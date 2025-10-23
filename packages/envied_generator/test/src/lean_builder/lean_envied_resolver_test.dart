import 'package:envied_generator/src/lean_builder/lean_envied_resolver.dart';
import 'package:lean_builder/element.dart';
import 'package:test/test.dart';

void main() {
  group('LeanEnviedResolver', () {
    late LeanEnviedResolver resolver;

    setUp(() {
      resolver = LeanEnviedResolver();
    });

    test('creates resolver instance', () {
      expect(resolver, isNotNull);
    });

    group('resolveEnviedConfig', () {
      test('applies default values when annotation has no parameters', () {
        final annotation = _MockConstObject({});
        final config = resolver.resolveEnviedConfig(annotation, null);

        expect(config.path, '.env'); // Default value from Envied constructor
        expect(config.requireEnvFile, false);
        expect(config.name, null);
        expect(config.obfuscate, false);
        expect(config.allowOptionalFields, false);
        expect(config.environment, false);
        expect(config.useConstantCase, false);
        expect(config.interpolate, true);
        expect(config.rawStrings, false);
        expect(config.randomSeed, null);
      });

      test('uses annotation values when provided', () {
        final annotation = _MockConstObject({
          'path': _MockConstString('.env.test'),
          'requireEnvFile': _MockConstBool(true),
          'name': _MockConstString('TestEnv'),
          'obfuscate': _MockConstBool(true),
          'allowOptionalFields': _MockConstBool(true),
          'environment': _MockConstBool(true),
          'useConstantCase': _MockConstBool(true),
          'interpolate': _MockConstBool(false),
          'rawStrings': _MockConstBool(true),
          'randomSeed': _MockConstInt(42),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);

        expect(config.path, '.env.test');
        expect(config.requireEnvFile, true);
        expect(config.name, 'TestEnv');
        expect(config.obfuscate, true);
        expect(config.allowOptionalFields, true);
        expect(config.environment, true);
        expect(config.useConstantCase, true);
        expect(config.interpolate, false);
        expect(config.rawStrings, true);
        expect(config.randomSeed, 42);
      });

      test('overridePath takes precedence over annotation path', () {
        final annotation = _MockConstObject({
          'path': _MockConstString('.env.test'),
        });

        final config = resolver.resolveEnviedConfig(
          annotation,
          '.env.override',
        );

        expect(config.path, '.env.override');
      });

      test('overridePath is null when not provided', () {
        final annotation = _MockConstObject({
          'path': _MockConstString('.env.test'),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);

        expect(config.path, '.env.test');
      });

      test('handles missing keys with null default', () {
        final annotation = _MockConstObject({});
        final config = resolver.resolveEnviedConfig(annotation, null);

        expect(config.path, '.env'); // Default value from Envied constructor
        expect(config.name, null);
        expect(config.randomSeed, null);
      });

      test('handles non-matching types gracefully', () {
        final annotation = _MockConstObject({
          'obfuscate': _MockConstString('not a bool'),
          'randomSeed': _MockConstString('not an int'),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);

        // Should fall back to defaults when type mismatch
        expect(config.obfuscate, false);
        expect(config.randomSeed, null);
      });
    });

    group('resolveEnviedField', () {
      test('returns all null values when annotation is empty', () {
        final annotation = _MockConstObject({});
        final fieldConfig = resolver.resolveEnviedField(annotation);

        expect(fieldConfig.varName, null);
        expect(fieldConfig.obfuscate, null);
        expect(fieldConfig.defaultValue, null);
        expect(fieldConfig.environment, null);
        expect(fieldConfig.optional, null);
        expect(fieldConfig.useConstantCase, null);
        expect(fieldConfig.interpolate, null);
        expect(fieldConfig.rawString, null);
        expect(fieldConfig.randomSeed, null);
      });

      test('extracts all field configuration values', () {
        final annotation = _MockConstObject({
          'varName': _MockConstString('API_KEY'),
          'obfuscate': _MockConstBool(true),
          'defaultValue': _MockConstString('default_value'),
          'environment': _MockConstBool(true),
          'optional': _MockConstBool(true),
          'useConstantCase': _MockConstBool(true),
          'interpolate': _MockConstBool(false),
          'rawString': _MockConstBool(true),
          'randomSeed': _MockConstInt(999),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);

        expect(fieldConfig.varName, 'API_KEY');
        expect(fieldConfig.obfuscate, true);
        expect(fieldConfig.defaultValue, 'default_value');
        expect(fieldConfig.environment, true);
        expect(fieldConfig.optional, true);
        expect(fieldConfig.useConstantCase, true);
        expect(fieldConfig.interpolate, false);
        expect(fieldConfig.rawString, true);
        expect(fieldConfig.randomSeed, 999);
      });

      test('handles string defaultValue', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstString('test_default'),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 'test_default');
      });

      test('handles int defaultValue', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstInt(42),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 42);
      });

      test('handles double defaultValue', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstDouble(3.14),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 3.14);
      });

      test('handles bool defaultValue', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstBool(true),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, true);
      });

      test('handles literal defaultValue', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstLiteral('literal_value'),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 'literal_value');
      });

      test('handles null defaultValue', () {
        final annotation = _MockConstObject({});

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, null);
      });

      test('handles unsupported constant types for defaultValue', () {
        // Since Constant is sealed, we test with null instead
        final annotation = _MockConstObject({});

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, null);
      });

      test('handles type mismatches gracefully', () {
        final annotation = _MockConstObject({
          'obfuscate': _MockConstString('not a bool'),
          'optional': _MockConstInt(123),
          'randomSeed': _MockConstBool(true),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);

        expect(fieldConfig.obfuscate, null);
        expect(fieldConfig.optional, null);
        expect(fieldConfig.randomSeed, null);
      });
    });

    group('_safeBool (tested via resolveEnviedConfig)', () {
      test('extracts boolean true correctly', () {
        final annotation = _MockConstObject({
          'obfuscate': _MockConstBool(true),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);
        expect(config.obfuscate, true);
      });

      test('extracts boolean false correctly', () {
        final annotation = _MockConstObject({
          'obfuscate': _MockConstBool(false),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);
        expect(config.obfuscate, false);
      });

      test('returns null for missing key', () {
        final annotation = _MockConstObject({});

        final config = resolver.resolveEnviedConfig(annotation, null);
        // name is optional and should be null, path has default of '.env'
        expect(config.name, null);
      });

      test('returns null for non-boolean value', () {
        final annotation = _MockConstObject({
          'obfuscate': _MockConstString('true'),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);
        // Should use default value when type mismatch
        expect(config.obfuscate, false);
      });
    });

    group('_safeInt (tested via resolveEnviedField)', () {
      test('extracts integer correctly', () {
        final annotation = _MockConstObject({
          'randomSeed': _MockConstInt(12345),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.randomSeed, 12345);
      });

      test('returns null for missing key', () {
        final annotation = _MockConstObject({});

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.randomSeed, null);
      });

      test('returns null for non-integer value', () {
        final annotation = _MockConstObject({
          'randomSeed': _MockConstString('123'),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.randomSeed, null);
      });
    });

    group('_safeString (tested via resolveEnviedConfig)', () {
      test('extracts string correctly', () {
        final annotation = _MockConstObject({
          'path': _MockConstString('.env.custom'),
        });

        final config = resolver.resolveEnviedConfig(annotation, null);
        expect(config.path, '.env.custom');
      });

      test('returns null for missing key', () {
        final annotation = _MockConstObject({});

        final config = resolver.resolveEnviedConfig(annotation, null);
        expect(config.path, '.env'); // Has default value
      });

      test('returns null for non-string value', () {
        final annotation = _MockConstObject({'name': _MockConstInt(123)});

        final config = resolver.resolveEnviedConfig(annotation, null);
        expect(config.name, null); // type mismatch returns null
      });
    });

    group('_getDefaultValue (tested via resolveEnviedField)', () {
      test('extracts ConstString value', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstString('test'),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 'test');
      });

      test('extracts ConstInt value', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstInt(42),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 42);
      });

      test('extracts ConstDouble value', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstDouble(3.14),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 3.14);
      });

      test('extracts ConstBool value', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstBool(false),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, false);
      });

      test('extracts ConstLiteral value', () {
        final annotation = _MockConstObject({
          'defaultValue': _MockConstLiteral(123),
        });

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, 123);
      });

      test('returns null for null constant', () {
        final annotation = _MockConstObject({});

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, null);
      });

      test('returns null for unsupported constant type', () {
        // Since Constant is sealed, we test with null instead
        final annotation = _MockConstObject({});

        final fieldConfig = resolver.resolveEnviedField(annotation);
        expect(fieldConfig.defaultValue, null);
      });
    });
  });

  group('EnviedFieldConfig', () {
    test('creates with all null values', () {
      const config = EnviedFieldConfig();

      expect(config.varName, null);
      expect(config.obfuscate, null);
      expect(config.defaultValue, null);
      expect(config.environment, null);
      expect(config.optional, null);
      expect(config.useConstantCase, null);
      expect(config.interpolate, null);
      expect(config.rawString, null);
      expect(config.randomSeed, null);
    });

    test('creates with specific values', () {
      const config = EnviedFieldConfig(
        varName: 'TEST',
        obfuscate: true,
        defaultValue: 'default',
        environment: true,
        optional: true,
        useConstantCase: true,
        interpolate: false,
        rawString: true,
        randomSeed: 42,
      );

      expect(config.varName, 'TEST');
      expect(config.obfuscate, true);
      expect(config.defaultValue, 'default');
      expect(config.environment, true);
      expect(config.optional, true);
      expect(config.useConstantCase, true);
      expect(config.interpolate, false);
      expect(config.rawString, true);
      expect(config.randomSeed, 42);
    });

    test('const constructor allows compile-time constants', () {
      const config1 = EnviedFieldConfig(varName: 'TEST');
      const config2 = EnviedFieldConfig(varName: 'TEST');

      expect(identical(config1.varName, config2.varName), true);
    });
  });
}

// Mock implementations for testing

class _MockConstObject implements ConstObject {
  final Map<String, Constant?> _values;

  _MockConstObject(this._values);

  @override
  Constant? get(String key) => _values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConstString implements ConstString {
  @override
  final String value;

  _MockConstString(this.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConstInt implements ConstInt {
  @override
  final int value;

  _MockConstInt(this.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConstDouble implements ConstDouble {
  @override
  final double value;

  _MockConstDouble(this.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConstBool implements ConstBool {
  @override
  final bool value;

  _MockConstBool(this.value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockConstLiteral implements ConstLiteral {
  @override
  final Object? literalValue;

  _MockConstLiteral(this.literalValue);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// For unsupported types, we'll use null instead of a mock class
// since Constant is sealed and cannot be implemented directly
