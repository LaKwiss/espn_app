import 'dart:developer';

class OddsService {
  static (double away, double home, double draw) calculateProbabilities(
    Map<String, dynamic> oddsJson,
  ) {
    if (!oddsJson.containsKey('items') ||
        oddsJson['items'] is! List ||
        (oddsJson['items'] as List).isEmpty) {
      log('Invalid or empty odds JSON structure, using default probabilities');
      return (0.33, 0.33, 0.34);
    }

    final List items = oddsJson['items'] as List;
    Map<String, dynamic>? providerOdds;

    try {
      providerOdds = _findOddsProvider(items, '2000');
      if (providerOdds != null) {
        final result = _extractBet365Odds(providerOdds);
        if (result != null) return result;
      }
    } catch (e) {
      log('Error processing Bet365 odds: $e');
    }

    try {
      providerOdds = _findOddsProvider(items, '58');
      if (providerOdds != null) {
        final result = _extractESPNBetOdds(providerOdds);
        if (result != null) return result;
      }
    } catch (e) {
      log('Error processing ESPN BET odds: $e');
    }

    return (0.33, 0.33, 0.34);
  }

  static Map<String, dynamic>? _findOddsProvider(
    List items,
    String providerId,
  ) {
    for (var item in items) {
      if (item is Map<String, dynamic> &&
          item.containsKey('provider') &&
          item['provider'] is Map<String, dynamic> &&
          item['provider'].containsKey('id') &&
          item['provider']['id'].toString() == providerId) {
        return item;
      }
    }
    return null;
  }

  static (double, double, double)? _extractBet365Odds(
    Map<String, dynamic> providerOdds,
  ) {
    if (providerOdds.containsKey('awayTeamOdds') &&
        providerOdds.containsKey('homeTeamOdds') &&
        providerOdds.containsKey('drawOdds')) {
      var awayOddsValue = _extractOddsValue(providerOdds, 'awayTeamOdds');
      var homeOddsValue = _extractOddsValue(providerOdds, 'homeTeamOdds');
      var drawOddsValue = _extractDrawOddsValue(providerOdds);

      if (awayOddsValue != null &&
          homeOddsValue != null &&
          drawOddsValue != null) {
        return _normalizeProbabilities(
          awayOddsValue,
          homeOddsValue,
          drawOddsValue,
        );
      }
    }
    return null;
  }

  static (double, double, double)? _extractESPNBetOdds(
    Map<String, dynamic> providerOdds,
  ) {
    double? awayOdds, homeOdds, drawOdds;

    if (_canAccessPath(providerOdds, ['awayTeamOdds', 'moneyLine']) &&
        _canAccessPath(providerOdds, ['homeTeamOdds', 'moneyLine']) &&
        _canAccessPath(providerOdds, ['drawOdds', 'moneyLine'])) {
      awayOdds = _americanToDecimalOdds(
        providerOdds['awayTeamOdds']['moneyLine'],
      );
      homeOdds = _americanToDecimalOdds(
        providerOdds['homeTeamOdds']['moneyLine'],
      );
      drawOdds = _americanToDecimalOdds(providerOdds['drawOdds']['moneyLine']);
    } else if (_canAccessPath(providerOdds, [
          'awayTeamOdds',
          'current',
          'moneyLine',
          'decimal',
        ]) &&
        _canAccessPath(providerOdds, [
          'homeTeamOdds',
          'current',
          'moneyLine',
          'decimal',
        ]) &&
        _canAccessPath(providerOdds, ['current', 'draw', 'decimal'])) {
      awayOdds =
          providerOdds['awayTeamOdds']['current']['moneyLine']['decimal'];
      homeOdds =
          providerOdds['homeTeamOdds']['current']['moneyLine']['decimal'];
      drawOdds = providerOdds['current']['draw']['decimal'];
    } else if (_canAccessPath(providerOdds, [
          'awayTeamOdds',
          'current',
          'moneyLine',
          'value',
        ]) &&
        _canAccessPath(providerOdds, [
          'homeTeamOdds',
          'current',
          'moneyLine',
          'value',
        ]) &&
        _canAccessPath(providerOdds, ['current', 'draw', 'value'])) {
      awayOdds = providerOdds['awayTeamOdds']['current']['moneyLine']['value'];
      homeOdds = providerOdds['homeTeamOdds']['current']['moneyLine']['value'];
      drawOdds = providerOdds['current']['draw']['value'];
    } else if (_canAccessPath(providerOdds, [
          'awayTeamOdds',
          'current',
          'moneyLine',
          'american',
        ]) &&
        _canAccessPath(providerOdds, [
          'homeTeamOdds',
          'current',
          'moneyLine',
          'american',
        ]) &&
        _canAccessPath(providerOdds, ['current', 'draw', 'american'])) {
      String awayAmerican =
          providerOdds['awayTeamOdds']['current']['moneyLine']['american'];
      String homeAmerican =
          providerOdds['homeTeamOdds']['current']['moneyLine']['american'];
      String drawAmerican = providerOdds['current']['draw']['american'];

      awayOdds = _americanStringToDecimalOdds(awayAmerican);
      homeOdds = _americanStringToDecimalOdds(homeAmerican);
      drawOdds = _americanStringToDecimalOdds(drawAmerican);
    }

    if (awayOdds != null && homeOdds != null && drawOdds != null) {
      return _normalizeProbabilities(awayOdds, homeOdds, drawOdds);
    }

    return null;
  }

  static bool _canAccessPath(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;

    for (var key in path) {
      if (current is! Map || !current.containsKey(key)) {
        return false;
      }
      current = current[key];
      if (current == null) {
        return false;
      }
    }

    return true;
  }

  static double? _extractOddsValue(
    Map<String, dynamic> providerOdds,
    String teamKey,
  ) {
    try {
      if (_canAccessPath(providerOdds, [teamKey, 'odds', 'value'])) {
        var value = providerOdds[teamKey]['odds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      if (_canAccessPath(providerOdds, [
        teamKey,
        'current',
        'moneyLine',
        'value',
      ])) {
        var value = providerOdds[teamKey]['current']['moneyLine']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      if (_canAccessPath(providerOdds, [
        teamKey,
        'current',
        'moneyLine',
        'decimal',
      ])) {
        var value = providerOdds[teamKey]['current']['moneyLine']['decimal'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      if (_canAccessPath(providerOdds, [teamKey, 'moneyLine'])) {
        var value = providerOdds[teamKey]['moneyLine'];
        if (value is num) {
          return _americanToDecimalOdds(value);
        }
      }

      return null;
    } catch (e) {
      log('Error extracting odds for $teamKey: $e');
      return null;
    }
  }

  static double? _extractDrawOddsValue(Map<String, dynamic> providerOdds) {
    try {
      if (_canAccessPath(providerOdds, ['drawOdds', 'value'])) {
        var value = providerOdds['drawOdds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      if (_canAccessPath(providerOdds, ['drawOdds', 'moneyLine'])) {
        var value = providerOdds['drawOdds']['moneyLine'];
        return value is num ? _americanToDecimalOdds(value) : null;
      }

      if (_canAccessPath(providerOdds, ['current', 'draw', 'value'])) {
        var value = providerOdds['current']['draw']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      if (_canAccessPath(providerOdds, ['current', 'draw', 'decimal'])) {
        var value = providerOdds['current']['draw']['decimal'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      return null;
    } catch (e) {
      log('Error extracting draw odds: $e');
      return null;
    }
  }

  static double _americanToDecimalOdds(dynamic americanOdds) {
    if (americanOdds == null) return 2.0;

    try {
      final num value =
          (americanOdds is num)
              ? americanOdds
              : double.parse(americanOdds.toString());

      if (value > 0) {
        return 1 + (value / 100);
      } else if (value < 0) {
        return 1 + (100 / -value);
      } else {
        return 2.0;
      }
    } catch (e) {
      log('Error converting American odds: $e');
      return 2.0;
    }
  }

  static double _americanStringToDecimalOdds(String americanOdds) {
    if (americanOdds == "EVEN") return 2.0;

    try {
      String cleaned = americanOdds.replaceAll(RegExp(r'[^0-9\-]'), '');

      if (cleaned.isEmpty) return 2.0;

      int value = int.parse(cleaned);

      if (value > 0) {
        return 1 + (value / 100);
      } else if (value < 0) {
        return 1 + (100 / -value);
      } else {
        return 2.0;
      }
    } catch (e) {
      log('Error converting American odds string: $e');
      return 2.0;
    }
  }

  static (double away, double home, double draw) _normalizeProbabilities(
    double awayOdds,
    double homeOdds,
    double drawOdds,
  ) {
    final double rawAway = 1 / awayOdds;
    final double rawHome = 1 / homeOdds;
    final double rawDraw = 1 / drawOdds;

    final double totalRaw = rawAway + rawHome + rawDraw;
    final double normAway = rawAway / totalRaw;
    final double normHome = rawHome / totalRaw;
    final double normDraw = rawDraw / totalRaw;

    return (normAway, normHome, normDraw);
  }
}
