#include "my_application.h"
#include <cstdio>

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

static GtkWindow* window;
// TODO: I don't know why this works. My screen is not 1920x1080.
static int screenWidth = 1920;
static int screenHeight = 1080;
static int barHeight = 32;

static bool isGrabbingOverlayInput = false;

static cairo_region_t *regionBar;
static cairo_region_t *regionBarAndOverlay;

static FlMethodResponse* grab_overlay_input(bool grab) {
  // Only execute if there is a change.
  if (grab != isGrabbingOverlayInput) {
    // Clear input region.
    gtk_widget_input_shape_combine_region(GTK_WIDGET(window), NULL);

    if (grab) {
      gtk_widget_input_shape_combine_region(GTK_WIDGET(window), regionBarAndOverlay);
      gtk_layer_set_keyboard_mode(window, GTK_LAYER_SHELL_KEYBOARD_MODE_EXCLUSIVE);
    } else {
      gtk_widget_input_shape_combine_region(GTK_WIDGET(window), regionBar);
      gtk_layer_set_keyboard_mode(window, GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);
    }
    isGrabbingOverlayInput = grab;
  }

  g_autoptr(FlValue) result = fl_value_new_null();
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}


static void input_region_call_handler(FlMethodChannel* channel,
                                        FlMethodCall* method_call,
                                        gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(method_call), "grabOverlayInput") == 0) {
    FlValue* args = fl_method_call_get_args(method_call);
    FlValue* grabValue = fl_value_lookup_string(args, "grab");
    bool grab = fl_value_get_bool(grabValue);
    response = grab_overlay_input(grab);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send response: %s", error->message);
  }
}
struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlMethodChannel* input_region_channel;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // layer shell config
  gtk_layer_init_for_window(GTK_WINDOW(window));
  gtk_layer_set_layer (GTK_WINDOW(window), GTK_LAYER_SHELL_LAYER_TOP);
  // gtk_layer_auto_exclusive_zone_enable (GTK_WINDOW(window));
  gtk_layer_set_exclusive_zone(GTK_WINDOW(window), barHeight);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
  // gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
  gtk_layer_set_anchor(GTK_WINDOW(window), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);


  // Initially, there is no keyboard input.
  // Input is grabbed when the mouse input is grabbed too.
  gtk_layer_set_keyboard_mode(window, GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "memex_bar");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "memex_bar");
  }

  GtkCssProvider* css = gtk_css_provider_new();
  gtk_css_provider_load_from_data (
    css,
    "window { background-color: transparent; }",
    -1,
    NULL
  );
  GtkStyleContext* context = gtk_widget_get_style_context(GTK_WIDGET(window));
  gtk_style_context_add_provider(context,
                                GTK_STYLE_PROVIDER(css),
                                GTK_STYLE_PROVIDER_PRIORITY_USER);

  gtk_window_set_default_size(window, 1280, 720);

  // Initialize mouse input regions.
  cairo_rectangle_int_t rect = {
    .x = 0,
    .y = 0,
    .width = screenWidth,
    .height = barHeight,
  };
  regionBar = cairo_region_create_rectangle(&rect);
  rect.height = screenHeight;
  regionBarAndOverlay = cairo_region_create_rectangle(&rect);

  // Initially limit mouse input region to the bar.
  isGrabbingOverlayInput = false;
  gtk_widget_input_shape_combine_region(GTK_WIDGET(window), regionBar);

  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Setup MethodChannel
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->input_region_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "bar.memex/input_region", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->input_region_channel, input_region_call_handler, self, nullptr);

  gtk_widget_set_size_request(GTK_WIDGET(view), 0, screenHeight);
  //g_signal_connect(G_OBJECT(view), "draw", G_CALLBACK(draw_callback), NULL);
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  // Clean up input regions.
  cairo_region_destroy(regionBar);
  cairo_region_destroy(regionBarAndOverlay);

  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->input_region_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
