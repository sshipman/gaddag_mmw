/// A GADDAG is a specialized graph, a data structure used to store strings for efficient lookup of
/// the existence of a string starting from any character within it.
/// This is achieved by storing both a (non-empty) reversed prefix, separator value,
/// and suffix for each letter in the word.
///
/// For example, the word "explain" will be stored with all of the following paths
/// e+xplain
/// xe+plain
/// pxe+lain
/// lpxe+ain
/// alpxe+in
/// ialpxe+n
/// nialpxe
library;

export 'src/gaddag_mmw_base.dart';