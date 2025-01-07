import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rnd_game/cell_view.dart';
import 'package:rnd_game/exploding_atoms.dart';
import 'package:rnd_game/exploding_atoms_repository.dart';
import 'package:rnd_game/exploding_atoms_stream_provider.dart';
import 'package:rnd_game/shared_preferences_repository.dart';

class ExplodingAtomsView extends ConsumerStatefulWidget {
  const ExplodingAtomsView({super.key});

  @override
  ConsumerState<ExplodingAtomsView> createState() => _ExplodingAtomsViewState();
}

class _ExplodingAtomsViewState extends ConsumerState<ExplodingAtomsView> {
  late final ExplodingAtoms explodingAtoms;
  late final String playerId;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await SharedPreferencesRepository.getUid();
      playerId = data ?? '';
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
                    ? ExplodingAtoms.createEmpty(
                        id: playerId + DateTime.now().toString())
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
                                final copy = await explodingAtoms.addAtom(i, j);
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
              ExplodingAtoms.createEmpty(
                  id: playerId + DateTime.now().toString()),
            );
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
