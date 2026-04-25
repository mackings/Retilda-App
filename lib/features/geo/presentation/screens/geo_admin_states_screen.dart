import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retilda/Views/Geo/api/geo_service.dart';
import 'package:retilda/core/theme/app_theme.dart';
import 'package:retilda/model/geo.dart';

class GeoAdminStatesScreen extends ConsumerStatefulWidget {
  const GeoAdminStatesScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GeoAdminStatesScreenState();
}

class _GeoAdminStatesScreenState extends ConsumerState<GeoAdminStatesScreen> {
  final GeoService _service = GeoService();
  final TextEditingController _stateController = TextEditingController();

  bool _loading = true;
  List<OperationalState> _states = [];

  Future<void> _loadStates() async {
    setState(() => _loading = true);
    final response = await _service.listStates();
    if (!mounted) return;
    setState(() {
      _states = response.data ?? [];
      _loading = false;
    });
  }

  Future<void> _addState() async {
    final name = _stateController.text.trim();
    if (name.isEmpty) return;
    final result = await _service.addState(name);
    if (result.success == true) {
      _stateController.clear();
      await _loadStates();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to add state')),
      );
    }
  }

  Future<void> _deactivateState(String id) async {
    final result = await _service.deactivateState(id);
    if (result.success == true) {
      await _loadStates();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Failed to deactivate state')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: AppTheme.surface,
        titleSpacing: 16,
        title: Text(
          'Manage states',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
          ),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(color: AppTheme.accent),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _loadStates,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  _StatesHero(totalStates: _states.length),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'Add operational state',
                    subtitle:
                        'Expand delivery coverage by adding new operational locations.',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: AppTheme.ink.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            hintText: 'Add state e.g. Lagos',
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _addState,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.add_location_alt_rounded),
                            label: const Text('Add state'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'Configured states',
                    subtitle:
                        'Review active coverage and deactivate states when needed.',
                  ),
                  const SizedBox(height: 12),
                  if (_states.isEmpty)
                    const _EmptyStatesState()
                  else
                    ..._states.map(
                      (state) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _StateCard(
                          state: state,
                          onDeactivate: () => _deactivateState(state.id ?? ''),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatesHero extends StatelessWidget {
  final int totalStates;

  const _StatesHero({required this.totalStates});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3452), Color(0xFF145E8D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.location_city_rounded, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(
            '$totalStates operational states',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Control the states where delivery operations are available.',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.52),
          ),
        ),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  final OperationalState state;
  final VoidCallback onDeactivate;

  const _StateCard({
    required this.state,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final active = state.active == true;
    final accent = active ? const Color(0xFF1E8E5A) : AppTheme.accent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.location_city_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.name ?? 'State',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  active ? 'Currently active for operations' : 'Inactive',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (active)
            OutlinedButton(
              onPressed: onDeactivate,
              child: const Text('Deactivate'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Inactive',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyStatesState extends StatelessWidget {
  const _EmptyStatesState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          const Icon(Icons.map_outlined, size: 42, color: AppTheme.ocean),
          const SizedBox(height: 12),
          Text(
            'No states configured',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first operational state to start managing coverage.',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}
