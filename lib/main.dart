import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the coRlorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
    if (_screenshots.length > _position + 1) {
      setState(() {
        _position++;
        print(_screenshots[_position]);

        // This call to setState tells the Flutter framework that something has
        // changed in this State, which causes it to rerun the build method below
        // so that the display can reflect the updated values. If we changed
        // _counter without calling setState(), then the build method would not be
        // called again, and so nothing would appear to happen.
      });
      if (_screenshots.length < _position + 3) {
        _loadMore();
        print(_screenshots.length);
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

  Future<void> _loadToDelete() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final result = await prefs.getStringList('toDelete');

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
    print(result);
    setState(() {
      _toDelete.removeWhere((element) => result.contains(element));
    });
    _saveToDelete();
  }

  Future<void> _loadAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList();
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
        print(_screenshots.length);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isPhotoNext = _screenshots.length > _position + 1;
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('Test de lapplication de tri de photo'),
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

                          print(_toDelete.length);
                        } else if (direction == DismissDirection.endToStart) {
                          print("keep");
                        }
                        _incrementPosition();
                      },

                      child: AssetEntityImage(
                        _screenshots[_position],
                        isOriginal: false,
                        fit: BoxFit.contain, // Defaults to `true`.
                        thumbnailSize: const ThumbnailSize.square(
                          700,
                        ), // Preferred value.
                        thumbnailFormat:
                            ThumbnailFormat.jpeg, // Defaults to `jpeg`.
                      ),
                    ),
                  ),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: isPhotoNext ? null : Colors.redAccent,
      //   onPressed: isPhotoNext ? _incrementPosition : null,

      //   tooltip: 'Next Photo',
      //   child: const Icon(Icons.arrow_forward),
      // ),
      bottomNavigationBar: TextButton(
        onPressed: _deleteMarked,
        child: Text("Deleted marked photo (${_toDelete.length})"),
      ),
    );
  }
}
