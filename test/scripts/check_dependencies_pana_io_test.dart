import 'package:flutter_test/flutter_test.dart';

import '../../scripts/src/check_dependencies_pana_io.dart' as io;

/// Tests for `scripts/src/check_dependencies_pana_io.dart`.
///
/// Focus is the SPDX detector (`detectSpdxFromLicenseText`) — the
/// critical correctness boundary for B-60 (gemini's PR #267 ask was
/// LGPL/GPL distinction + fail-closed behaviour). The pub-cache disk
/// scanner is exercised by the integration runs in CI; here we cover
/// the deterministic content-classification logic.
void main() {
  group('detectSpdxFromLicenseText — disallowed licenses', () {
    test('detects AGPL-3.0', () {
      const text = '''
GNU AFFERO GENERAL PUBLIC LICENSE
Version 3, 19 November 2007
''';
      expect(io.detectSpdxFromLicenseText(text), 'AGPL-3.0');
    });

    test('detects LGPL-3.0 (NOT misclassified as GPL)', () {
      const text = '''
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
''';
      expect(
        io.detectSpdxFromLicenseText(text),
        'LGPL-3.0',
        reason:
            'LGPL header MUST match BEFORE the GPL fallback to avoid '
            'mis-classifying LGPL packages as the more restrictive GPL — '
            'this is the gemini PR #267 finding regression test',
      );
    });

    test('detects LGPL-2.1', () {
      const text = '''
GNU LESSER GENERAL PUBLIC LICENSE
Version 2.1, February 1999
''';
      expect(io.detectSpdxFromLicenseText(text), 'LGPL-2.1');
    });

    test('detects GPL-3.0', () {
      const text = '''
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
''';
      expect(io.detectSpdxFromLicenseText(text), 'GPL-3.0');
    });

    test('detects GPL-2.0', () {
      const text = '''
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
''';
      expect(io.detectSpdxFromLicenseText(text), 'GPL-2.0');
    });

    test('detects SSPL-1.0', () {
      const text = '''
Server Side Public License
VERSION 1, OCTOBER 16, 2018
''';
      expect(io.detectSpdxFromLicenseText(text), 'SSPL-1.0');
    });

    test('detects CC-BY-NC variants as non-commercial CC', () {
      const text = '''
Creative Commons Attribution-NonCommercial 4.0 International Public License
''';
      expect(io.detectSpdxFromLicenseText(text), 'CC-BY-NC-4.0');
    });
  });

  group('detectSpdxFromLicenseText — permissive licenses', () {
    test('detects MIT', () {
      const text = '''
MIT License

Copyright (c) 2026 Acme Co.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish ...
''';
      expect(io.detectSpdxFromLicenseText(text), 'MIT');
    });

    test('detects Apache-2.0', () {
      const text = '''
                                 Apache License
                           Version 2.0, January 2004
                        http://www.apache.org/licenses/

   TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
''';
      expect(io.detectSpdxFromLicenseText(text), 'Apache-2.0');
    });

    test('detects BSD-3-Clause via "neither the name of" clause', () {
      const text = '''
Copyright 2026 Acme Co.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Neither the name of Acme Co. nor the names of its contributors
    may be used to endorse or promote products derived from this
    software without specific prior written permission.
''';
      expect(io.detectSpdxFromLicenseText(text), 'BSD-3-Clause');
    });

    test('detects BSD-2-Clause when 3rd-clause language is absent', () {
      const text = '''
Copyright 2026 Acme Co.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the following
     disclaimer in the documentation and/or other materials provided
     with the distribution.
''';
      expect(io.detectSpdxFromLicenseText(text), 'BSD-2-Clause');
    });

    test('detects ISC', () {
      const text = '''
ISC License

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted ...
''';
      expect(io.detectSpdxFromLicenseText(text), 'ISC');
    });

    test('detects MPL-2.0', () {
      const text = '''
Mozilla Public License Version 2.0
==================================
''';
      expect(io.detectSpdxFromLicenseText(text), 'MPL-2.0');
    });

    test('detects Unlicense', () {
      const text = '''
This is free and unencumbered software released into the public domain.
''';
      expect(io.detectSpdxFromLicenseText(text), 'Unlicense');
    });

    test('detects CC0-1.0', () {
      const text = 'CC0 1.0 Universal';
      expect(io.detectSpdxFromLicenseText(text), 'CC0-1.0');
    });
  });

  group('detectSpdxFromLicenseText — ambiguous and edge cases', () {
    test('returns null on empty text', () {
      expect(io.detectSpdxFromLicenseText(''), isNull);
    });

    test('returns null on text with no license markers', () {
      const text = 'Copyright 2026. All rights reserved.';
      expect(
        io.detectSpdxFromLicenseText(text),
        isNull,
        reason:
            'unrecognised license must surface as `unknown` so the '
            'caller can fail-close in strict mode',
      );
    });

    test('MPL-2.0 with "Secondary License" boilerplate is NOT mis-classified '
        'as AGPL/GPL (gtk Dart package regression — observed locally during '
        'PR #267 fix-up)', () {
      const text = '''
Mozilla Public License Version 2.0
==================================

1. Definitions
--------------

1.12. "Secondary License"
    means either the GNU General Public License, Version 2.0, the GNU
    Lesser General Public License, Version 2.1, the GNU Affero General
    Public License, Version 3.0, or any later versions of those
    licenses.
''';
      expect(
        io.detectSpdxFromLicenseText(text),
        'MPL-2.0',
        reason:
            'permissive license header MUST short-circuit before the '
            'GPL family fallback — otherwise every MPL package would be '
            'mis-classified as AGPL because of its compatibility clause',
      );
    });

    test('matches case-insensitively across whitespace runs', () {
      // MIT body split across many lines + tabs.
      const text = '''
        permission\tis\thereby     granted, free of\n\tcharge,
        to\tany   person\nobtaining a copy of this software
        without\trestriction
      ''';
      expect(io.detectSpdxFromLicenseText(text), 'MIT');
    });
  });
}
