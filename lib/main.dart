import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const GrilleApp());

class GrilleApp extends StatelessWidget {
  const GrilleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grille de dessin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Formats de papier (dimensions en cm, portrait)
// ---------------------------------------------------------------------------
class PaperFormat {
  final String name;
  final double w;
  final double h;
  const PaperFormat(this.name, this.w, this.h);
}

const List<PaperFormat> kFormats = [
  PaperFormat('A0', 84.1, 118.9),
  PaperFormat('A1', 59.4, 84.1),
  PaperFormat('A2', 42.0, 59.4),
  PaperFormat('A3', 29.7, 42.0),
  PaperFormat('A4', 21.0, 29.7),
  PaperFormat('A5', 14.8, 21.0),
  PaperFormat('A6', 10.5, 14.8),
  PaperFormat('Personnalisé', 0, 0),
];

// ---------------------------------------------------------------------------
// Calque d'image (position et taille normalisées par rapport à la page)
// ---------------------------------------------------------------------------
class ImageLayer {
  final int id;
  final Uint8List bytes;
  double scale;
  Offset offset; // fraction de la largeur/hauteur de la page
  double opacity;
  bool visible;

  ImageLayer({
    required this.id,
    required this.bytes,
    this.scale = 1.0,
    this.offset = Offset.zero,
    this.opacity = 1.0,
    this.visible = true,
  });
}

// ---------------------------------------------------------------------------
// Peintre de la grille : tout est calculé en cm puis converti en pixels
// ---------------------------------------------------------------------------
class GridPainter extends CustomPainter {
  final double wCm;
  final double hCm;
  final double spacingCm;
  final Color color;
  final double opacity;
  final double thickness;
  final bool diagonals;

  GridPainter({
    required this.wCm,
    required this.hCm,
    required this.spacingCm,
    required this.color,
    required this.opacity,
    required this.thickness,
    required this.diagonals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (spacingCm <= 0 || wCm <= 0 || hCm <= 0) return;
    final pxPerCm = size.width / wCm;
    final step = spacingCm * pxPerCm;
    if (step < 3) return; // carreaux trop petits pour être affichés

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final cols = (wCm / spacingCm).floor();
    final rows = (hCm / spacingCm).floor();

    for (int i = 0; i <= cols; i++) {
      final x = i * step;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int j = 0; j <= rows; j++) {
      final y = j * step;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Diagonales en X dans chaque carreau complet
    if (diagonals) {
      final path = Path();
      for (int i = 0; i < cols; i++) {
        final x0 = i * step;
        final x1 = (i + 1) * step;
        for (int j = 0; j < rows; j++) {
          final y0 = j * step;
          final y1 = (j + 1) * step;
          path.moveTo(x0, y0);
          path.lineTo(x1, y1);
          path.moveTo(x1, y0);
          path.lineTo(x0, y1);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Cadre extérieur
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => true;
}

// ---------------------------------------------------------------------------
// Page principale
// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _palette = <Color>[
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.grey,
  ];

  final _pageKey = GlobalKey();

  PaperFormat _format = kFormats[4]; // A4 par défaut
  bool _landscape = false;
  double _w = 21.0;
  double _h = 29.7;
  double _spacing = 1.0;

  Color _color = Colors.black;
  double _opacity = 0.6;
  double _thickness = 1.0;
  bool _diagonals = false;

  final List<ImageLayer> _layers = []; // du fond (index 0) vers le dessus
  int _nextId = 0;
  int? _selectedId;
  double _baseScale = 1.0;

  bool _saving = false;

  late final TextEditingController _wCtrl = TextEditingController(text: '21');
  late final TextEditingController _hCtrl = TextEditingController(text: '29.7');
  late final TextEditingController _sCtrl = TextEditingController(text: '1');

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    _sCtrl.dispose();
    super.dispose();
  }

  // ------------------------------ helpers ---------------------------------
  String _fmt(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  double? _parse(String s) {
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  ImageLayer? get _selected {
    for (final l in _layers) {
      if (l.id == _selectedId) return l;
    }
    return null;
  }

  // ------------------------------ actions ---------------------------------
  void _selectFormat(PaperFormat f) {
    setState(() {
      _format = f;
      if (f.w > 0) {
        _w = _landscape ? f.h : f.w;
        _h = _landscape ? f.w : f.h;
        _wCtrl.text = _fmt(_w);
        _hCtrl.text = _fmt(_h);
      }
    });
  }

  void _setLandscape(bool landscape) {
    if (landscape == _landscape) return;
    setState(() {
      _landscape = landscape;
      final t = _w;
      _w = _h;
      _h = t;
      _wCtrl.text = _fmt(_w);
      _hCtrl.text = _fmt(_h);
    });
  }

  Future<void> _addImages() async {
    try {
      final files = await ImagePicker().pickMultiImage();
      if (files.isEmpty) return;
      final added = <ImageLayer>[];
      for (final x in files) {
        final bytes = await x.readAsBytes();
        final n = _layers.length + added.length;
        final first = n == 0;
        added.add(ImageLayer(
          id: ++_nextId,
          bytes: bytes,
          // Les images suivantes arrivent à moitié taille, à gauche/droite
          scale: first ? 1.0 : 0.5,
          offset: first ? Offset.zero : Offset(n.isOdd ? 0.25 : -0.25, 0),
        ));
      }
      setState(() {
        _layers.addAll(added);
        _selectedId = added.last.id;
      });
    } catch (e) {
      _snack('Impossible de charger l\'image : $e');
    }
  }

  void _moveLayer(int i, int d) {
    final j = i + d;
    if (j < 0 || j >= _layers.length) return;
    setState(() {
      final l = _layers.removeAt(i);
      _layers.insert(j, l);
    });
  }

  void _deleteLayer(ImageLayer l) {
    setState(() {
      _layers.remove(l);
      if (_selectedId == l.id) {
        _selectedId = _layers.isEmpty ? null : _layers.last.id;
      }
    });
  }

  Future<void> _export() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _pageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Résolution : ~300 dpi (118 px/cm), plafonnée à 6000 px sur le grand côté
      final maxSide = math.max(_w, _h);
      final pxPerCm = math.min(118.11, 6000 / maxSide);
      final pixelRatio = pxPerCm * _w / boundary.size.width;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      final name = 'grille_${DateTime.now().millisecondsSinceEpoch}';

      if (Platform.isAndroid || Platform.isIOS) {
        await Gal.putImageBytes(bytes, name: '$name.png');
        _snack('Image enregistrée dans la galerie.');
      } else {
        final dir = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(bytes);
        _snack('Image enregistrée : ${file.path}');
      }
    } catch (e) {
      _snack('Échec de l\'enregistrement : $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------ aperçu ----------------------------------
  Widget _preview() {
    return LayoutBuilder(builder: (context, box) {
      final availW = math.max(50.0, box.maxWidth - 24);
      final availH = math.max(50.0, box.maxHeight - 24);
      final ratio = _w / _h;
      double pw = availW;
      double ph = pw / ratio;
      if (ph > availH) {
        ph = availH;
        pw = ph * ratio;
      }
      return Container(
        color: Colors.grey.shade300,
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [BoxShadow(blurRadius: 12, color: Colors.black38)],
            ),
            child: SizedBox(
              width: pw,
              height: ph,
              child: RepaintBoundary(key: _pageKey, child: _page(pw, ph)),
            ),
          ),
        ),
      );
    });
  }

  Widget _page(double pw, double ph) {
    return Listener(
      onPointerSignal: (e) {
        final sel = _selected;
        if (e is PointerScrollEvent && sel != null) {
          setState(() {
            final f = e.scrollDelta.dy < 0 ? 1.1 : 1 / 1.1;
            sel.scale = (sel.scale * f).clamp(0.05, 5.0);
          });
        }
      },
      child: GestureDetector(
        onScaleStart: (_) => _baseScale = _selected?.scale ?? 1.0,
        onScaleUpdate: (d) {
          final sel = _selected;
          if (sel == null) return;
          setState(() {
            sel.scale = (_baseScale * d.scale).clamp(0.05, 5.0);
            sel.offset += Offset(
              d.focalPointDelta.dx / pw,
              d.focalPointDelta.dy / ph,
            );
          });
        },
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.white),
              for (final l in _layers)
                if (l.visible)
                  Opacity(
                    key: ValueKey(l.id),
                    opacity: l.opacity,
                    child: Transform.translate(
                      offset: Offset(l.offset.dx * pw, l.offset.dy * ph),
                      child: Transform.scale(
                        scale: l.scale,
                        child: Image.memory(
                          l.bytes,
                          width: pw,
                          height: ph,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  ),
              IgnorePointer(
                child: CustomPaint(
                  painter: GridPainter(
                    wCm: _w,
                    hCm: _h,
                    spacingCm: _spacing,
                    color: _color,
                    opacity: _opacity,
                    thickness: _thickness,
                    diagonals: _diagonals,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------- contrôles --------------------------------
  Widget _section(String id, String title, List<Widget> children,
      {bool open = false}) {
    return ExpansionTile(
      key: ValueKey(id),
      initiallyExpanded: open,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _numField({
    required String label,
    required TextEditingController ctrl,
    required ValueChanged<double> onValid,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'cm',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (s) {
        final v = _parse(s);
        if (v != null) setState(() => onValid(v));
      },
    );
  }

  Widget _layerTile(ImageLayer l, int index) {
    final selected = l.id == _selectedId;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedId = l.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.memory(l.bytes,
                    width: 38, height: 38, fit: BoxFit.cover, cacheWidth: 80),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Image ${l.id}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ),
              _miniBtn(l.visible ? Icons.visibility : Icons.visibility_off,
                  () => setState(() => l.visible = !l.visible)),
              _miniBtn(Icons.arrow_upward, () => _moveLayer(index, 1)),
              _miniBtn(Icons.arrow_downward, () => _moveLayer(index, -1)),
              _miniBtn(Icons.delete_outline, () => _deleteLayer(l)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _controls() {
    final sel = _selected;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _section('fmt', 'Format de la page', [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in kFormats)
                ChoiceChip(
                  label: Text(f.name),
                  selected: _format == f,
                  onSelected: (_) => _selectFormat(f),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                  value: false,
                  icon: Icon(Icons.stay_current_portrait),
                  label: Text('Portrait')),
              ButtonSegment(
                  value: true,
                  icon: Icon(Icons.stay_current_landscape),
                  label: Text('Paysage')),
            ],
            selected: {_landscape},
            onSelectionChanged: (s) => _setLandscape(s.first),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _numField(
                  label: 'Largeur',
                  ctrl: _wCtrl,
                  onValid: (v) {
                    _w = v;
                    _format = kFormats.last;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField(
                  label: 'Hauteur',
                  ctrl: _hCtrl,
                  onValid: (v) {
                    _h = v;
                    _format = kFormats.last;
                  },
                ),
              ),
            ],
          ),
        ], open: true),
        _section('grid', 'Grille', [
          _numField(
            label: 'Distance entre les lignes',
            ctrl: _sCtrl,
            onValid: (v) => _spacing = v,
          ),
          CheckboxListTile(
            value: _diagonals,
            onChanged: (v) => setState(() => _diagonals = v ?? false),
            title: const Text('Diagonales en X'),
            subtitle: const Text('Dans chaque carreau complet'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const Text('Couleur'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _palette)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black26,
                        width: _color == c ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Opacité : ${(_opacity * 100).round()} %'),
          Slider(
            value: _opacity,
            min: 0.05,
            max: 1,
            onChanged: (v) => setState(() => _opacity = v),
          ),
          Text('Épaisseur : ${_thickness.toStringAsFixed(1)}'),
          Slider(
            value: _thickness,
            min: 0.5,
            max: 4,
            onChanged: (v) => setState(() => _thickness = v),
          ),
        ]),
        _section('layers', 'Calques d\'images (${_layers.length})', [
          FilledButton.tonalIcon(
            onPressed: _addImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Ajouter des images'),
          ),
          const SizedBox(height: 8),
          if (_layers.isEmpty)
            const Text(
              'Aucune image pour le moment.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          // Affichage du calque du dessus vers le fond
          for (int i = _layers.length - 1; i >= 0; i--)
            _layerTile(_layers[i], i),
          if (sel != null) ...[
            const SizedBox(height: 8),
            Text('Taille : ${(sel.scale * 100).round()} %'),
            Slider(
              value: sel.scale.clamp(0.05, 5.0),
              min: 0.05,
              max: 5,
              onChanged: (v) => setState(() => sel.scale = v),
            ),
            Text('Opacité du calque : ${(sel.opacity * 100).round()} %'),
            Slider(
              value: sel.opacity,
              min: 0.05,
              max: 1,
              onChanged: (v) => setState(() => sel.opacity = v),
            ),
            const Text(
              'Glissez sur la page pour déplacer le calque sélectionné, '
              'pincez ou utilisez la molette pour le redimensionner.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                sel.scale = 1.0;
                sel.offset = Offset.zero;
              }),
              icon: const Icon(Icons.center_focus_strong),
              label: const Text('Recentrer le calque'),
            ),
          ],
        ], open: true),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _saving ? null : _export,
          icon: const Icon(Icons.save_alt),
          label: const Text('Enregistrer en PNG'),
        ),
        const SizedBox(height: 20),
      ],
      ),
    );
  }

  // ------------------------------- build ----------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width > 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grille de dessin'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer en PNG',
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_alt),
            onPressed: _saving ? null : _export,
          ),
        ],
      ),
      // Menu hamburger : le bouton apparaît automatiquement dans l'AppBar
      drawer: Drawer(
        width: math.min(340.0, size.width * 0.88),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Réglages',
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _controls()),
            ],
          ),
        ),
      ),
      // Sur grand écran, on garde la page visible pendant les réglages
      drawerScrimColor: wide ? Colors.transparent : null,
      body: SafeArea(child: _preview()),
    );
  }
}