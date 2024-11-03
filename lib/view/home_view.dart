import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:picgenie/utils/app_colors.dart';

import '../model/bloc/prompt_bloc.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  TextEditingController controller = TextEditingController();
  final PromptBloc promptBloc = PromptBloc();
  Uint8List? generatedImage;

  @override
  void initState() {
    promptBloc.add(PromptInitialEvent());
    super.initState();
  }

  void reset() {
    controller.clear();
    promptBloc.add(PromptInitialEvent());
    setState(() {
      generatedImage = null;
    });
  }

  Future<void> requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
  }

  Future<void> saveImageToDevice(Uint8List imageBytes) async {
    try {
      // Request storage permission before saving
      await requestStoragePermission();
      if (await Permission.storage.isGranted) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final filePath = path.join(
            directory.path,
            "generated_image_${DateTime.now().millisecondsSinceEpoch}.png",
          );

          final file = File(filePath);
          await file.writeAsBytes(imageBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image saved to ${file.path}"),
              backgroundColor: AppColor.themeColor.withOpacity(0.9),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Unable to access storage directory"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Storage permission is required to save images"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save image: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bgColor,
      appBar: AppBar(
        backgroundColor: AppColor.themeColor,
        centerTitle: true,
        elevation: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        title: const Text(
          "PicGenie",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: reset,
            tooltip: "Reset",
          ),
        ],
      ),
      body: BlocConsumer<PromptBloc, PromptState>(
        bloc: promptBloc,
        listener: (context, state) {
          if (state is PromptGeneratingImageSuccessState) {
            setState(() {
              generatedImage = state.uint8list;
            });
          }
        },
        builder: (context, state) {
          if (state is PromptGeneratingImageLoadState) {
            return const Center(child: CircularProgressIndicator(color: AppColor.themeColor));
          } else if (state is PromptGeneratingImageErrorState) {
            return const Center(child: Text("Something went wrong", style: TextStyle(color: Colors.redAccent)));
          } else if (state is PromptGeneratingImageSuccessState) {
            final successState = state;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: MemoryImage(successState.uint8list),
                      ),
                    ),
                  ),
                ),
                buildPromptInputSection(),
              ],
            );
          } else {
            return buildPromptInputSection();
          }
        },
      ),
    );
  }

  // Helper widget for the input section
  Widget buildPromptInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColor.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Enter your prompt",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColor.themeColor),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            cursorColor: AppColor.themeColor,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: "Type something inspiring...",
              hintStyle: TextStyle(color: Colors.grey[500]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColor.themeColor),
                borderRadius: BorderRadius.circular(16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColor.themeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      promptBloc.add(PromptEnteredEvent(prompt: controller.text));
                    }
                  },
                  icon: const Icon(Icons.image_rounded, size: 22, color: Colors.white),
                  label: const Text(
                    "Generate Image",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.download, color: AppColor.themeColor, size: 28),
                onPressed: generatedImage != null ? () => saveImageToDevice(generatedImage!) : null,
                tooltip: "Download Image",
              ),
            ],
          ),
        ],
      ),
    );
  }
}
