// Generated by CoffeeScript 2.2.1
(function() {
  // Source maps allow JavaScript runtimes to match running JavaScript back to
  // the original source code that corresponds to it. This can be minified
  // JavaScript, but in our case, we're concerned with mapping pretty-printed
  // JavaScript back to CoffeeScript.

  // In order to produce maps, we must keep track of positions (line number, column number)
  // that originated every node in the syntax tree, and be able to generate a
  // [map file](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit)
  // — which is a compact, VLQ-encoded representation of the JSON serialization
  // of this information — to write out alongside the generated JavaScript.

  // LineMap
  // -------

  // A **LineMap** object keeps track of information about original line and column
  // positions for a single line of output JavaScript code.
  // **SourceMaps** are implemented in terms of **LineMaps**.
  var LineMap, SourceMap;

  LineMap = class LineMap {
    constructor(line1) {
      this.line = line1;
      this.columns = [];
    }

    add(column, [sourceLine, sourceColumn], options = {}) {
      if (this.columns[column] && options.noReplace) {
        return;
      }
      return this.columns[column] = {
        line: this.line,
        column,
        sourceLine,
        sourceColumn
      };
    }

    sourceLocation(column) {
      var mapping;
      while (!((mapping = this.columns[column]) || (column <= 0))) {
        column--;
      }
      return mapping && [mapping.sourceLine, mapping.sourceColumn];
    }

  };

  SourceMap = (function() {
    var BASE64_CHARS, VLQ_CONTINUATION_BIT, VLQ_SHIFT, VLQ_VALUE_MASK;

    // SourceMap
    // ---------

    // Maps locations in a single generated JavaScript file back to locations in
    // the original CoffeeScript source file.

    // This is intentionally agnostic towards how a source map might be represented on
    // disk. Once the compiler is ready to produce a "v3"-style source map, we can walk
    // through the arrays of line and column buffer to produce it.
    class SourceMap {
      constructor() {
        this.lines = [];
      }

      // Adds a mapping to this SourceMap. `sourceLocation` and `generatedLocation`
      // are both `[line, column]` arrays. If `options.noReplace` is true, then if there
      // is already a mapping for the specified `line` and `column`, this will have no
      // effect.
      add(sourceLocation, generatedLocation, options = {}) {
        var base, column, line, lineMap;
        [line, column] = generatedLocation;
        lineMap = ((base = this.lines)[line] || (base[line] = new LineMap(line)));
        return lineMap.add(column, sourceLocation, options);
      }

      // Look up the original position of a given `line` and `column` in the generated
      // code.
      sourceLocation([line, column]) {
        var lineMap;
        while (!((lineMap = this.lines[line]) || (line <= 0))) {
          line--;
        }
        return lineMap && lineMap.sourceLocation(column);
      }

      // V3 SourceMap Generation
      // -----------------------

      // Builds up a V3 source map, returning the generated JSON as a string.
      // `options.sourceRoot` may be used to specify the sourceRoot written to the source
      // map.  Also, `options.sourceFiles` and `options.generatedFile` may be passed to
      // set "sources" and "file", respectively.
      generate(options = {}, code = null) {
        var buffer, i, j, lastColumn, lastSourceColumn, lastSourceLine, len, len1, lineMap, lineNumber, mapping, needComma, ref, ref1, sources, v3, writingline;
        writingline = 0;
        lastColumn = 0;
        lastSourceLine = 0;
        lastSourceColumn = 0;
        needComma = false;
        buffer = "";
        ref = this.lines;
        for (lineNumber = i = 0, len = ref.length; i < len; lineNumber = ++i) {
          lineMap = ref[lineNumber];
          if (lineMap) {
            ref1 = lineMap.columns;
            for (j = 0, len1 = ref1.length; j < len1; j++) {
              mapping = ref1[j];
              if (!(mapping)) {
                continue;
              }
              while (writingline < mapping.line) {
                lastColumn = 0;
                needComma = false;
                buffer += ";";
                writingline++;
              }
              // Write a comma if we've already written a segment on this line.
              if (needComma) {
                buffer += ",";
                needComma = false;
              }
              // Write the next segment. Segments can be 1, 4, or 5 values.  If just one, then it
              // is a generated column which doesn't match anything in the source code.

              // The starting column in the generated source, relative to any previous recorded
              // column for the current line:
              buffer += this.encodeVlq(mapping.column - lastColumn);
              lastColumn = mapping.column;
              // The index into the list of sources:
              buffer += this.encodeVlq(0);
              // The starting line in the original source, relative to the previous source line.
              buffer += this.encodeVlq(mapping.sourceLine - lastSourceLine);
              lastSourceLine = mapping.sourceLine;
              // The starting column in the original source, relative to the previous column.
              buffer += this.encodeVlq(mapping.sourceColumn - lastSourceColumn);
              lastSourceColumn = mapping.sourceColumn;
              needComma = true;
            }
          }
        }
        // Produce the canonical JSON object format for a "v3" source map.
        sources = options.sourceFiles ? options.sourceFiles : options.filename ? [options.filename] : ['<anonymous>'];
        v3 = {
          version: 3,
          file: options.generatedFile || '',
          sourceRoot: options.sourceRoot || '',
          sources: sources,
          names: [],
          mappings: buffer
        };
        if (options.sourceMap || options.inlineMap) {
          v3.sourcesContent = [code];
        }
        return v3;
      }

      encodeVlq(value) {
        var answer, nextChunk, signBit, valueToEncode;
        answer = '';
        // Least significant bit represents the sign.
        signBit = value < 0 ? 1 : 0;
        // The next bits are the actual value.
        valueToEncode = (Math.abs(value) << 1) + signBit;
        // Make sure we encode at least one character, even if valueToEncode is 0.
        while (valueToEncode || !answer) {
          nextChunk = valueToEncode & VLQ_VALUE_MASK;
          valueToEncode = valueToEncode >> VLQ_SHIFT;
          if (valueToEncode) {
            nextChunk |= VLQ_CONTINUATION_BIT;
          }
          answer += this.encodeBase64(nextChunk);
        }
        return answer;
      }

      encodeBase64(value) {
        return BASE64_CHARS[value] || (function() {
          throw new Error(`Cannot Base64 encode value: ${value}`);
        })();
      }

    };

    // Base64 VLQ Encoding
    // -------------------

    // Note that SourceMap VLQ encoding is "backwards".  MIDI-style VLQ encoding puts
    // the most-significant-bit (MSB) from the original value into the MSB of the VLQ
    // encoded value (see [Wikipedia](https://en.wikipedia.org/wiki/File:Uintvar_coding.svg)).
    // SourceMap VLQ does things the other way around, with the least significat four
    // bits of the original value encoded into the first byte of the VLQ encoded value.
    VLQ_SHIFT = 5;

    VLQ_CONTINUATION_BIT = 1 << VLQ_SHIFT; // 0010 0000

    VLQ_VALUE_MASK = VLQ_CONTINUATION_BIT - 1; // 0001 1111

    // Regular Base64 Encoding
    // -----------------------
    BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    return SourceMap;

  }).call(this);

  // Our API for source maps is just the `SourceMap` class.
  module.exports = SourceMap;

}).call(this);
