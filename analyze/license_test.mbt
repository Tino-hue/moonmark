test "detect MIT license" {
  let text = "MIT License\n\nPermission is hereby granted, free of charge, to any person obtaining a copy"
  assert_eq(detect_license(text), Some("MIT"))
}

test "detect Apache-2.0 license" {
  let text = "Apache License\nVersion 2.0, January 2004\nhttp://www.apache.org/licenses/"
  assert_eq(detect_license(text), Some("Apache-2.0"))
}

test "detect BSD-3-Clause license" {
  let text = "BSD 3-Clause License\n\nRedistribution and use in source and binary forms, with or without modification"
  assert_eq(detect_license(text), Some("BSD-3-Clause"))
}

test "detect BSD-2-Clause license" {
  let text = "Simplified BSD License\n\nTwo-Clause BSD License"
  assert_eq(detect_license(text), Some("BSD-2-Clause"))
}

test "detect GPL-3.0 license" {
  let text = "GNU GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007\n\nCopyright (C) 2007 Free Software Foundation"
  assert_eq(detect_license(text), Some("GPL-3.0"))
}

test "detect AGPL-3.0 license" {
  let text = "GNU AFFERO GENERAL PUBLIC LICENSE\nVersion 3, 19 November 2007"
  assert_eq(detect_license(text), Some("AGPL-3.0"))
}

test "detect LGPL-3.0 license" {
  let text = "GNU LESSER GENERAL PUBLIC LICENSE\nVersion 3, 29 June 2007"
  assert_eq(detect_license(text), Some("LGPL-3.0"))
}

test "detect MPL-2.0 license" {
  let text = "Mozilla Public License Version 2.0\n1. Definitions"
  assert_eq(detect_license(text), Some("MPL-2.0"))
}

test "detect ISC license" {
  let text = "ISC License\n\nPermission to use, copy, modify, and/or distribute this software"
  assert_eq(detect_license(text), Some("ISC"))
}

test "detect Unlicense" {
  let text = "This is free and unencumbered software released into the public domain.\n\nThe Unlicense"
  assert_eq(detect_license(text), Some("Unlicense"))
}

test "detect CC0-1.0" {
  let text = "CC0 1.0 Universal\n\nCreative Commons Zero"
  assert_eq(detect_license(text), Some("CC0-1.0"))
}

test "detect SSPL-1.0" {
  let text = "Server Side Public License\nVERSION 1, 22 OCTOBER 2018\nSSPL"
  assert_eq(detect_license(text), Some("SSPL-1.0"))
}

test "detect unknown license returns None" {
  let text = "Some completely random text that does not match any known license"
  assert_eq(detect_license(text), None)
}

test "extract SPDX tag" {
  let text = "// SPDX-License-Identifier: MIT\n// Some code here"
  assert_eq(detect_license(text), Some("MIT"))
}

test "extract SPDX tag Apache" {
  let text = "# SPDX-License-Identifier: Apache-2.0\n# Module description"
  assert_eq(detect_license(text), Some("Apache-2.0"))
}

test "GPL is high risk" {
  assert_true(is_high_risk_license("GPL-3.0"))
  assert_true(is_high_risk_license("GPL-2.0"))
  assert_true(is_high_risk_license("AGPL-3.0"))
  assert_true(is_high_risk_license("SSPL-1.0"))
}

test "MIT is not high risk" {
  assert_false(is_high_risk_license("MIT"))
}

test "Apache is not high risk" {
  assert_false(is_high_risk_license("Apache-2.0"))
}

test "license name mapping" {
  assert_eq(license_name("MIT"), "MIT License")
  assert_eq(license_name("Apache-2.0"), "Apache License 2.0")
  assert_eq(license_name("GPL-3.0"), "GNU General Public License v3.0")
  assert_eq(license_name("AGPL-3.0"), "GNU Affero General Public License v3.0")
  assert_eq(license_name("Unknown-X"), "Unknown License")
}

test "LGPL does not match GPL" {
  // LGPL text should not be misidentified as GPL
  let text = "GNU LESSER GENERAL PUBLIC LICENSE Version 3"
  assert_eq(detect_license(text), Some("LGPL-3.0"))
  assert_false(is_high_risk_license("LGPL-3.0"))
}

test "AGPL does not match GPL" {
  // AGPL text should not be misidentified as GPL
  let text = "GNU AFFERO GENERAL PUBLIC LICENSE Version 3"
  assert_eq(detect_license(text), Some("AGPL-3.0"))
  assert_true(is_high_risk_license("AGPL-3.0"))
}
