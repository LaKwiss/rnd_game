import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell_view.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_repository.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';

class ExplodingAtomsView extends ConsumerWidget {
  const ExplodingAtomsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explodingAtomsAsync = ref.watch(explodingAtomsStreamProvider);

    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            height: 400,
            width: 400,
            child: explodingAtomsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (explodingAtomsList) {
                // Prendre le premier jeu ou créer un nouveau si la liste est vide
                final explodingAtoms = explodingAtomsList.isEmpty
                    ? ExplodingAtoms.empty
                    : explodingAtomsList.first;

                return Column(
                  children: [
                    for (int i = 0; i < 8; i++)
                      Row(
                        children: [
                          for (int j = 0; j < 8; j++)
                            CellView(
                              explodingAtoms.grid[i * 8 + j],
                              () async {
                                final copy = explodingAtoms.addAtom(i, j);
                                await ExplodingAtomsRepository
                                    .sendExplodingAtoms(copy);
                              },
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await ExplodingAtomsRepository.sendExplodingAtoms(
              ExplodingAtoms.empty,
            );
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
