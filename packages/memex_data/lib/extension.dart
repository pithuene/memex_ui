import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'state/state.dart';

class ReactiveQuery<OBJ, R> extends ChangeNotifier
    implements ReactiveValue<List<R>> {
  final QueryBuilder<OBJ, R, QQueryOperations> _query;

  ReactiveQuery(this._query) {
    _query.watchLazy(fireImmediately: true).listen((_) {
      print("Query changed");
      notifyListeners();
    });
  }

  @override
  List<R> get value {
    print("Query getter");
    ReactiveListener.currentContextListener?.listenTo(this);
    return _query.findAllSync();
  }
}

extension ToReactive<OBJ, R> on QueryBuilder<OBJ, R, QQueryOperations> {
  ReactiveValue<List<R>> reactive() {
    return ReactiveQuery<OBJ, R>(this);
  }
}
