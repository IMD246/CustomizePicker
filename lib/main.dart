import 'dart:typed_data';

import 'package:customize_picker/customize_picker.dart' show PickerHelper;
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
  List<AssetEntity> selectedAssetList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: selectedAssetList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          AssetEntity assetEntity = selectedAssetList[index];
          return Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                Positioned.fill(
                  child: StreamBuilder<Uint8List?>(
                    initialData: null,
                    stream: assetEntity
                        .thumbnailDataWithSize(
                          const ThumbnailSize(200, 200),
                          quality: 60,
                        )
                        .asStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SizedBox(
                          child: Image.memory(
                            snapshot.data!,
                            key: ValueKey(assetEntity.id),
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            cacheHeight: 200,
                          ),
                        );
                      }
                      return Container();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          PickerHelper.pickAssets(
            requestType: RequestType.all,
            selectedAssetlist: selectedAssetList,
            context: context,
          ).then((value) {
            setState(() {
              if (value != null) selectedAssetList = value;
            });
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
