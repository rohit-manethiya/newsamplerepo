/**
 * Created by mertyalti on 18/05/2018.
 */

public with sharing class Encoder {
    static final List<String> HTML_DECODER  = new List<String> { '&', '<', '>', '"', '\''};
    static final List<String> HTML_ENCODER  = new List<String> { '&amp;', '&lt;', '&gt;', '&quot;', '&#39;' };

    static final List<String> JS_DECODER = new List<String> { '\\', '\'', '\n', '\r', '"', '!--', '/', '<', '>' };
    static final List<String> JS_ENCODER = new List<String> { '\\\\', '\\\'', '\\n', '\\r', '\\"', '\\!--', '\\/', '\\u003C', '\\u003E' };

    static final List<String> JSINHTML_DECODER = new List<String> { '&', '\\', '\'', '"', '\r', '\n', '<', '>' };
    static final List<String> JSINHTML_ENCODER = new List<String> { '\\&amp;', '\\\\', '\\&#39;', '\\&quot;', '\\r', '\\n', '&lt;', '&gt;' };

    private String encode(String encodeString, List<String> sourceEncode, String[] toEncode) {
        if (String.isBlank(encodeString))
            return encodeString;

        for (Integer i = 0; i < sourceEncode.size(); ++i) {
            encodeString = encodeString.replace(sourceEncode[i], toEncode[i]);
        }

        return encodeString;
    }

    public String encodeJS(String encodeString) {
        return encode(encodeString, JS_DECODER, JS_ENCODER);
    }

    public String encodeHTML(String encodeString) {
        return encode(encodeString, HTML_DECODER, HTML_ENCODER);
    }

    public String encodeJSINHTML(String encodeString) {
        return encode(encodeString, JSINHTML_DECODER, JSINHTML_ENCODER);
    }

}