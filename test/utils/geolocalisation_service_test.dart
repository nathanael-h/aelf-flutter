import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two pure helpers [GeolocalisationService.detectAndPropose] builds on:
/// [GeolocalisationService.offeredCandidates] decides what to actually show
/// (a diocese is always paired with its country), and
/// [GeolocalisationService.proposalSignature] is the dedup key persisted so
/// the exact same detected answer is not re-proposed every hour — only a
/// change in what would be proposed should produce a different signature.
void main() {
  group('proposalSignature', () {
    test('order does not matter: the candidate set is what counts', () {
      expect(
        GeolocalisationService.proposalSignature(['valence', 'grenoble']),
        GeolocalisationService.proposalSignature(['grenoble', 'valence']),
      );
    });

    test('a different candidate set yields a different signature', () {
      expect(
        GeolocalisationService.proposalSignature(['valence']),
        isNot(GeolocalisationService.proposalSignature(['grenoble'])),
      );
      expect(
        GeolocalisationService.proposalSignature(['valence']),
        isNot(
            GeolocalisationService.proposalSignature(['valence', 'grenoble'])),
      );
    });

    test('known vs. unknown (unregistered diocese) never collide', () {
      expect(
        GeolocalisationService.proposalSignature(['valence']),
        isNot(GeolocalisationService.proposalSignature(['valence'],
            unknown: true)),
      );
    });

    test('is stable across calls with the same input', () {
      expect(
        GeolocalisationService.proposalSignature(['france']),
        GeolocalisationService.proposalSignature(['france']),
      );
    });
  });

  group('offeredCandidates', () {
    test('a diocese is always paired with France', () {
      expect(GeolocalisationService.offeredCandidates(['lyon']),
          unorderedEquals(['lyon', 'france']));
    });

    test('two overlapping dioceses are both paired with France', () {
      expect(GeolocalisationService.offeredCandidates(['valence', 'grenoble']),
          unorderedEquals(['valence', 'grenoble', 'france']));
    });

    test('a stable country/continent id is offered alone', () {
      for (final id in ['france', 'belgique', 'suisse', 'romain', 'afrique']) {
        expect(GeolocalisationService.offeredCandidates([id]), [id],
            reason: id);
      }
    });

    test('France is never duplicated when already among the candidates', () {
      // Not a real detection shape today, but the set must stay a set.
      expect(GeolocalisationService.offeredCandidates(['lyon', 'france']),
          unorderedEquals(['lyon', 'france']));
    });
  });
}
