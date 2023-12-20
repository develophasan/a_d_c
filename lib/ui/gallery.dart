import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../helper/image_classification_helper.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  ImageClassificationHelper? imageClassificationHelper;
  final imagePicker = ImagePicker();
  String? imagePath;
  img.Image? image;
  Map<String, double>? classification;
  bool cameraIsAvailable = Platform.isAndroid || Platform.isIOS;

  @override
  void initState() {
    imageClassificationHelper = ImageClassificationHelper();
    imageClassificationHelper!.initHelper();
    super.initState();
  }

  void cleanResult() {
    imagePath = null;
    image = null;
    classification = null;
    setState(() {});
  }

  Future<void> processImage() async {
    if (imagePath != null) {
      final imageData = File(imagePath!).readAsBytesSync();
      image = img.decodeImage(imageData);
      setState(() {});
      classification = await imageClassificationHelper?.inferenceImage(image!);
      setState(() {});
    }
  }

  @override
  void dispose() {
    imageClassificationHelper?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (cameraIsAvailable)
                TextButton.icon(
                  onPressed: () async {
                    cleanResult();
                    final result = await imagePicker.pickImage(
                      source: ImageSource.camera,
                    );

                    imagePath = result?.path;
                    setState(() {});
                    processImage();
                  },
                  icon: const Icon(
                    Icons.camera,
                    size: 24,
                  ),
                  label: const Text("Fotoğraf Çek"),
                ),
              TextButton.icon(
                onPressed: () async {
                  cleanResult();
                  final result = await imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );

                  imagePath = result?.path;
                  setState(() {});
                  processImage();
                },
                icon: const Icon(
                  Icons.photo,
                  size: 24,
                ),
                label: const Text("Galeriden Al"),
              ),
            ],
          ),
          const Divider(color: Colors.black),
          Expanded(
              child: Stack(
            alignment: Alignment.center,
            children: [
              if (imagePath != null) Image.file(File(imagePath!)),
              if (image == null)
                const Text("Bir fotoğraf çekin veya galeriden bir tane seçin"),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(),
                  if (image != null) ...[
                    if (imageClassificationHelper?.inputTensor != null)
                      Text(
                        'Input: (shape: ${imageClassificationHelper?.inputTensor.shape} type: '
                        '${imageClassificationHelper?.inputTensor.type})',
                      ),
                    if (imageClassificationHelper?.outputTensor != null)
                      Text(
                        'Output: (shape: ${imageClassificationHelper?.outputTensor.shape} '
                        'type: ${imageClassificationHelper?.outputTensor.type})',
                      ),
                    const SizedBox(height: 8),
                    Text('Num channels: ${image?.numChannels}'),
                    Text('Bits per channel: ${image?.bitsPerChannel}'),
                    Text('Height: ${image?.height}'),
                    Text('Width: ${image?.width}'),
                  ],
                  const Spacer(),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        if (classification != null)
                          ...(classification!.entries.toList()
                                ..sort(
                                  (a, b) => a.value.compareTo(b.value),
                                ))
                              .reversed
                              .take(3)
                              .map(
                                (e) => Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.white,
                                  child: Row(
                                    children: [
                                      Text(e.key),
                                      const Spacer(),
                                      Text(e.value.toStringAsFixed(2))
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          )),
        ],
      ),
    );
  }
}
