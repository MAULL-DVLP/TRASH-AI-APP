import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2E7D32),
        scaffoldBackgroundColor: const Color(0xFFE8F5E9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          brightness: Brightness.light,
          background: const Color(0xFFE8F5E9),
          surface: Colors.white,
          secondary: const Color(0xFF66BB6A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF43A047),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF81C784),
          brightness: Brightness.dark,
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
          secondary: const Color(0xFF66BB6A),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF66BB6A),
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: HomePage(
        isDarkMode: isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? imageFile;
  Interpreter? interpreter;

  String result = 'Belum ada hasil';

  bool isModelReady = false;
  bool isProcessing = false;

  // GANTI SESUAI print(class_names) DARI COLAB
  final List<String> labels = const [
    'battery',
    'biological',
    'brown-glass',
    'cardboard',
    'clothes',
    'green-glass',
    'metal',
    'paper',
    'plastic',
    'shoes',
    'trash',
    'white-glass',
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
  try {
    debugPrint("=== LOAD MODEL DIMULAI ===");

    interpreter = await Interpreter.fromAsset(
  'assets/trash_model.tflite',
);

    debugPrint("=== MODEL BERHASIL ===");

    final inputShape =
        interpreter!.getInputTensor(0).shape;

    final outputShape =
        interpreter!.getOutputTensor(0).shape;

    debugPrint("INPUT SHAPE: $inputShape");
    debugPrint("OUTPUT SHAPE: $outputShape");

    setState(() {
      isModelReady = true;
    });

  } catch (e) {
    debugPrint("=== ERROR LOAD MODEL ===");
    debugPrint(e.toString());
  }
}

  Future<void> pickImage() async {
    if (!isModelReady || isProcessing) return;

    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile == null) return;

    setState(() {
      imageFile = File(pickedFile.path);
      result = 'Memproses...';
      isProcessing = true;
    });

    await predictImage();
  }

  Future<void> predictImage() async {
    try {
      final imageFile = this.imageFile;
      final interpreter = this.interpreter;

      if (imageFile == null || interpreter == null) {
        debugPrint('Interpreter belum siap');
        setState(() {
          isProcessing = false;
        });
        return;
      }

      final rawBytes = await imageFile.readAsBytes();

      final image = img.decodeImage(rawBytes);

      if (image == null) {
        debugPrint("Gagal decode image");

        setState(() {
          isProcessing = false;
        });

        return;
      }

      // Resize sesuai model
      final resizedImage = img.copyResize(
        image,
        width: 224,
        height: 224,
      );

      // INPUT TENSOR
      final input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(
            224,
            (x) {
              final pixel = resizedImage.getPixel(x, y);

              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
          ),
        ),
      );

      // OUTPUT TENSOR
      final output = List.generate(
        1,
        (_) => List.filled(labels.length, 0.0),
      );

      // RUN MODEL
      interpreter.run(input, output);

      debugPrint("OUTPUT MODEL:");
      debugPrint(output.toString());

      // AMBIL INDEX TERBESAR
      int maxIndex = 0;
      double maxValue = output[0][0];

      for (int i = 1; i < output[0].length; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          maxIndex = i;
        }
      }

      final scores = List.generate(
        labels.length,
        (i) => MapEntry(labels[i], output[0][i]),
      )..sort((a, b) => b.value.compareTo(a.value));

      debugPrint("Top-3 hasil: ${scores.take(3).map((e) => '${e.key}:${e.value.toStringAsFixed(4)}').join(', ')}");
      debugPrint("Hasil: ${labels[maxIndex]}");
      debugPrint("Confidence: $maxValue");

      setState(() {
        result =
            "${labels[maxIndex]}\nConfidence: ${(maxValue * 100).toStringAsFixed(2)}%";

        isProcessing = false;
      });
    } catch (e) {
      debugPrint("ERROR PREDICT: $e");

      setState(() {
        result = "Terjadi Error";
        isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Sampah AI'),
        centerTitle: true,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.dark_mode),
            tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.light ? Colors.black12 : Colors.black26,
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.recycling, color: colors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Scan sampah kamu dengan cepat dan lihat hasil klasifikasi secara langsung.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface.withOpacity(0.85),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: theme.brightness == Brightness.light ? const Color(0xFFF1F8E9) : const Color(0xFF263238),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: imageFile != null
                              ? Image.file(
                                  imageFile!,
                                  key: ValueKey(imageFile!.path),
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  key: const ValueKey('placeholder'),
                                  color: theme.brightness == Brightness.light ? const Color(0xFFF1F8E9) : const Color(0xFF263238),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.photo_camera, size: 56, color: colors.primary),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Belum ada gambar',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: colors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isModelReady ? colors.primary.withOpacity(0.12) : colors.secondary.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isModelReady ? 'Model Siap' : 'Memuat model...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isModelReady ? colors.primary : colors.secondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isModelReady ? 'Mulai scan sekarang' : 'Tunggu sebentar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.brightness == Brightness.light ? Colors.black12 : Colors.black26,
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Hasil Deteksi',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          result,
                          key: ValueKey(result),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isProcessing)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton.icon(
                        onPressed: isModelReady ? pickImage : null,
                        icon: const Icon(Icons.camera_alt, size: 22),
                        label: Text(
                          isModelReady ? 'Scan Sampah' : 'Memuat model...',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}