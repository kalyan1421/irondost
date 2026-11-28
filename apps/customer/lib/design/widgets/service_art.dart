import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The illustrated service set (`assets/illustrations/*.svg`): one picture per kind of work or garment.
enum ServiceArt {
  laundry('laundry'),
  ironing('ironing'),
  saree('saree'),
  carpets('carpets'),
  dryClean('dry-clean'),
  washFold('wash-fold'),
  shirt('shirt'),
  trousers('trousers'),
  pickupBag('pickup-bag');

  const ServiceArt(this._file);
  final String _file;

  String get asset => 'assets/illustrations/$_file.svg';

  /// The picture that best matches a category or item name or slug, or [fallback] when nothing does.
  static ServiceArt match(
    String text, {
    ServiceArt fallback = ServiceArt.shirt,
  }) {
    final s = text.toLowerCase();
    bool has(List<String> words) => words.any(s.contains);
    if (has(['saree', 'sari'])) {
      return saree;
    }
    if (has(['carpet', 'rug'])) {
      return carpets;
    }
    if (has(['laundry'])) {
      return laundry;
    }
    if (has(['dry', 'suit', 'blazer', 'coat'])) {
      return dryClean;
    }
    if (has(['trouser', 'pant', 'jean'])) {
      return trousers;
    }
    if (has(['shirt'])) {
      return shirt;
    }
    if (has(['fold', 'bedsheet', 'towel', 'blanket', 'curtain'])) {
      return washFold;
    }
    if (has(['iron', 'press'])) {
      return ironing;
    }
    if (has(['wash', 'laundry'])) {
      return laundry;
    }
    return fallback;
  }
}

/// A [ServiceArt] picture at a square [size]. Decorative: the label next to it carries the meaning.
class ServiceArtImage extends StatelessWidget {
  const ServiceArtImage(this.art, {super.key, this.size = 56});

  final ServiceArt art;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      art.asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    ),
  );
}

/// A soft rounded tile holding a [ServiceArtImage]: the thumbnail used in lists.
class ServiceArtTile extends StatelessWidget {
  const ServiceArtTile(this.art, {super.key, this.size = 56, this.background});

  final ServiceArt art;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background ?? Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: ServiceArtImage(art, size: size * 0.78),
  );
}
