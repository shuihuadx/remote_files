import 'dart:collection';

class LruCache<K, V> {
  final int _capacity;
  final LinkedHashMap<K, V> _map;

  LruCache(this._capacity) : _map = LinkedHashMap();

  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    // 在访问键值对后，将其重新插入以更新其访问顺序
    var value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void set(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= _capacity) {
      // 删除最久未使用的元素
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }

  void remove(K key) {
    _map.remove(key);
  }

  int get length => _map.length;

  void clear() {
    _map.clear();
  }
}
