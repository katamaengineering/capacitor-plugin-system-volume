const base = require('@ionic/swiftlint-config');

// Extends the Ionic base config. This is a single small MPVolumeView plugin: the
// overlay-compositing plugin class runs a little past SwiftLint's conservative
// length defaults, and `x` / `y` are the honest names for the geometry the
// plugin exchanges with JS. Everything else stays on base.
module.exports = {
  ...base,
  // `unused_import` only runs under `swiftlint analyze`; the base lists it in
  // `opt_in_rules`, which makes `swiftlint lint` print a placement note. Move it
  // to `analyzer_rules` so a plain lint run is silent.
  opt_in_rules: base.opt_in_rules.filter((rule) => rule !== 'unused_import'),
  analyzer_rules: ['unused_import'],
  // Short, honest names: `x`/`y` for geometry, and `r`/`g`/`b`/`a`/`o` for the
  // colour channels the plugin unpacks when bridging CSS hex strings to UIColor.
  identifier_name: {
    excluded: ['id', 'x', 'y', 'r', 'g', 'b', 'a', 'o'],
  },
  type_body_length: {
    warning: 300,
    error: 400,
  },
  file_length: {
    warning: 500,
    error: 600,
  },
};
