import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorting App',
      theme: ThemeData(
      
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Sorting App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _position = 0;
  List<String> _toDelete = [];
  bool _isFinished = false;
  bool _isLoading = false;
  List<AssetEntity> _screenshots = [];
  AssetPathEntity? _album;
  void _incrementPosition() {
    if (_screenshots.length > _position + 1) { //to load the next page before the end of the current page.
      setState(() {
        _position++;

      });
      _savePosition();
      if (_screenshots.length < _position + 3) {
        _loadMore();
      }
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _loadToDelete();
  }

//We store the date beacause it didn't change, while the id can change when screenshots are deleted.
  Future<void> _savePosition() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final date = _screenshots[_position].createDateTime.millisecondsSinceEpoch;
    await prefs.setInt('lastDate', date);
  }

  Future<void> _loadToDelete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final result = prefs.getStringList('toDelete');

    if (result != null) {
      setState(() {
        _toDelete = result;
      });
    }
  }

  Future<void> _saveToDelete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('toDelete', _toDelete);
  }

//to avoid a double loading if a user swipe quickly.
  Future<void> _loadMore() async {
    if (_isLoading == true) {
      return;
    }
    final album = _album;
    if (null == album) {
      return;
    }
    _isLoading = true;
    try {
      List<AssetEntity> result = await album.getAssetListRange(
        start: _screenshots.length,
        end: _screenshots.length + 10,
      );
      setState(() {
        _screenshots.addAll(result);
      });
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _deleteMarked() async {
    final result = await PhotoManager.editor.deleteWithIds(_toDelete);
    setState(() {
      _toDelete.removeWhere((element) => result.contains(element));
    });
    _saveToDelete();
  }

  Future<void> _loadAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final test = prefs.getInt('lastDate');

    DateTime? myDate;
    if (test != null) {
      myDate = DateTime.fromMillisecondsSinceEpoch(test);
    }

    FilterOptionGroup? filter;

    if (myDate != null) {
      filter = FilterOptionGroup(
        createTimeCond: DateTimeCond(
          min: DateTime(2005),
          max: myDate.add(const Duration(seconds: 1)), //Margin to not exclude the save photo because the millisecond troncature
        ),
      );
    }
    final paths = await PhotoManager.getAssetPathList(filterOption: filter);

    for (var path in paths) {
      if (path.name == "Screenshots") {
        List<AssetEntity> result = await path.getAssetListRange(
          start: 0,
          end: 10,
        );
        setState(() {
          _screenshots = result;
          _album = path;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            _isFinished
                ? const Text('All screenshots sorted')
                : _screenshots.isEmpty
                ? CircularProgressIndicator()
                : Expanded(
                    child: Dismissible(
                      key: ValueKey(_screenshots[_position].id),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.startToEnd) {
                          setState(() {
                            _toDelete.add(_screenshots[_position].id);
                          });
                          _saveToDelete();
                        }
                        _incrementPosition();
                      },

                      child: AssetEntityImage(
                        _screenshots[_position],
                        isOriginal: false,
                        fit: BoxFit.contain, 
                        thumbnailSize: const ThumbnailSize.square(
                          700,
                        ), 
                        thumbnailFormat:
                            ThumbnailFormat.jpeg, 
                      ),
                    ),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: TextButton(
        onPressed: _deleteMarked, //retire only the deleted ids in the _toDelete list, because the user can close and cancel the confirmation IOS window
        child: Text("Deleted marked photo (${_toDelete.length})"),
      ),
    );
  }
}
