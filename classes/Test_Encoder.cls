/**
 * Created by mertyalti on 27/07/2018.
 */

@IsTest
private class Test_Encoder {
    @IsTest static void testJSEncoding() {
        Encoder enc = new Encoder();
        String alertText = '"This is a JS alert message for my test&<>!--"';
        String encodedJS = enc.encodeJS(alertText);
        System.assertEquals('\\"This is a JS alert message for my test&\\u003C\\u003E\\!--\\"',encodedJS);
    }
    @IsTest static void testHTMLEncoding() {
        Encoder enc = new Encoder();
        String alertText = '<span>This is a HTML &nbsp; text for my test</span>';
        String encodedHTML = enc.encodeHTML(alertText);
        System.assertEquals('&lt;span&gt;This is a HTML &amp;nbsp; text for my test&lt;/span&gt;',encodedHTML);
    }
    @IsTest static void testHTMLinJSEncoding() {
        Encoder enc = new Encoder();
        String alertText = '<span>This is a HTML &nbsp; text !-- for my test</span>';
        String encodedHTMLJS = enc.encodeJSINHTML(alertText);
        System.assertEquals('&lt;span&gt;This is a HTML \\\\&amp;nbsp; text !-- for my test&lt;/span&gt;',encodedHTMLJS);
    }
    @IsTest static void testEmptyEncoding() {
        Encoder enc = new Encoder();
        String alertText = '';
        String encodedJS = enc.encodeJS(alertText);
        System.assertEquals('',encodedJS);
    }
}