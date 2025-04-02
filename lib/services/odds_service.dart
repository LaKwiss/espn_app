import 'dart:developer';

class OddsService {
  /// Calculate probabilities based on odds data
  /// Returns a tuple of (away probability, home probability, draw probability)
  static (double away, double home, double draw) calculateProbabilities(
    Map<String, dynamic> oddsJson,
  ) {
    // Verify JSON structure is valid
    if (!oddsJson.containsKey('items') ||
        oddsJson['items'] is! List ||
        (oddsJson['items'] as List).isEmpty) {
      log('Invalid or empty odds JSON structure, using default probabilities');
      return (0.33, 0.33, 0.34);
    }

    final List items = oddsJson['items'] as List;
    Map<String, dynamic>? providerOdds;

    // Try Bet365 (id "2000") first
    try {
      providerOdds = _findOddsProvider(items, '2000');
      if (providerOdds != null) {
        final result = _extractBet365Odds(providerOdds);
        if (result != null) return result;
      }
    } catch (e) {
      log('Error processing Bet365 odds: $e');
    }

    // Try ESPN BET (id "58") if Bet365 failed
    try {
      providerOdds = _findOddsProvider(items, '58');
      if (providerOdds != null) {
        final result = _extractESPNBetOdds(providerOdds);
        if (result != null) return result;
      }
    } catch (e) {
      log('Error processing ESPN BET odds: $e');
    }

    // Default probabilities if no provider available
    return (0.33, 0.33, 0.34);
  }

  /// Find an odds provider by ID from the items list
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

  /// Extract odds from Bet365 format
  static (double, double, double)? _extractBet365Odds(
    Map<String, dynamic> providerOdds,
  ) {
    if (providerOdds.containsKey('awayTeamOdds') &&
        providerOdds.containsKey('homeTeamOdds') &&
        providerOdds.containsKey('drawOdds')) {
      // Extract odds values with safe access
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

  /// Extract odds from ESPN BET format (multiple possible formats)
  static (double, double, double)? _extractESPNBetOdds(
    Map<String, dynamic> providerOdds,
  ) {
    double? awayOdds, homeOdds, drawOdds;

    // Method 1: Direct moneyLine access
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
    }
    // Method 2: current.moneyLine.decimal format
    else if (_canAccessPath(providerOdds, [
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
    }
    // Method 3: current.moneyLine.value format
    else if (_canAccessPath(providerOdds, [
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
    }
    // Method 4: current.moneyLine.american format
    else if (_canAccessPath(providerOdds, [
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

  /// Safely check if a path exists in a Map
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

  /// Extract odds value safely using multiple possible paths
  static double? _extractOddsValue(
    Map<String, dynamic> providerOdds,
    String teamKey,
  ) {
    try {
      // Try direct format with 'odds.value'
      if (_canAccessPath(providerOdds, [teamKey, 'odds', 'value'])) {
        var value = providerOdds[teamKey]['odds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Try with 'current.moneyLine.value'
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

      // Try format 'current.moneyLine.decimal'
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

      // Try with moneyLine directly
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

  /// Extract draw odds value safely
  static double? _extractDrawOddsValue(Map<String, dynamic> providerOdds) {
    try {
      // Bet365 format
      if (_canAccessPath(providerOdds, ['drawOdds', 'value'])) {
        var value = providerOdds['drawOdds']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // Format with moneyLine
      if (_canAccessPath(providerOdds, ['drawOdds', 'moneyLine'])) {
        var value = providerOdds['drawOdds']['moneyLine'];
        return value is num ? _americanToDecimalOdds(value) : null;
      }

      // ESPN format with current
      if (_canAccessPath(providerOdds, ['current', 'draw', 'value'])) {
        var value = providerOdds['current']['draw']['value'];
        return value is num
            ? value.toDouble()
            : double.tryParse(value.toString());
      }

      // ESPN format with decimal
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

  /// Convert American odds format to decimal odds
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
        return 2.0; // Even odds
      }
    } catch (e) {
      log('Error converting American odds: $e');
      return 2.0; // Default value on error
    }
  }

  /// Convert American odds string to decimal odds
  static double _americanStringToDecimalOdds(String americanOdds) {
    if (americanOdds == "EVEN") return 2.0;

    try {
      // Remove non-numeric characters except minus sign
      String cleaned = americanOdds.replaceAll(RegExp(r'[^0-9\-]'), '');

      if (cleaned.isEmpty) return 2.0;

      int value = int.parse(cleaned);

      if (value > 0) {
        return 1 + (value / 100);
      } else if (value < 0) {
        return 1 + (100 / -value);
      } else {
        return 2.0; // Even odds
      }
    } catch (e) {
      log('Error converting American odds string: $e');
      return 2.0; // Default value on error
    }
  }

  /// Calculate normalized probabilities from decimal odds
  static (double away, double home, double draw) _normalizeProbabilities(
    double awayOdds,
    double homeOdds,
    double drawOdds,
  ) {
    // Calculate raw probabilities (inverse of odds)
    final double rawAway = 1 / awayOdds;
    final double rawHome = 1 / homeOdds;
    final double rawDraw = 1 / drawOdds;

    // Normalize so the sum is 1
    final double totalRaw = rawAway + rawHome + rawDraw;
    final double normAway = rawAway / totalRaw;
    final double normHome = rawHome / totalRaw;
    final double normDraw = rawDraw / totalRaw;

    return (normAway, normHome, normDraw);
  }
}
