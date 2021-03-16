@NamespaceAccessible
public with sharing class OperatorTypeCodes {

    @NamespaceAccessible public static Map<String, String> getStdObjectsWithoutNameField(){
        Map<String, String> fieldMap = new Map<String, String> {
                'event' => 'Subject',
                'task' => 'Subject',
                'contact' => 'LastName',
                'case' => 'CaseNumber',
                'solution' => 'SolutionName'
        };
        return fieldMap;
    }

    @NamespaceAccessible public static Map<String, String> getSummarizeByOperatorSembols(){
        Map<String, String> operatorSembol = new Map<String, String> {
                '--None--' => '--None--',
                'Sum' => 'Sum',
                'Average' => 'Average',
                'Min' => 'Min',
                'Max' => 'Max'
        };
        return operatorSembol;
    }

    @NamespaceAccessible public static Map<String, String> getOperatorSembols(){
        Map<String, String> operatorSembol = new Map<String, String> {
                '' => '--None--',
                'e' => ' = ',
                'n' => ' != ',
                's' => ' LIKE ',
                'c' => ' LIKE ',
                'k' => ' LIKE ',
                'l' => ' < ',
                'g' => ' > ',
                'm' => ' <= ',
                'h' => ' >= ',
                'u' => 'includes',
                'x' => 'excludes',
                'w' => 'within'
        };
        return operatorSembol;
    }

    @NamespaceAccessible public static Map<String, String> getOperatorCodes(){
        Map<String, String> operatorCodes = new Map<String, String> {
                '' => '--None--',
                'e' => 'equals',
                'n' => 'not equal to',
                's' => 'starts with',
                'c' => 'contains',
                'k' => 'does not contain',
                'l' => 'less than',
                'g' => 'greater than',
                'm' => 'less or equal',
                'h' => 'greater or equal',
                'u' => 'includes',
                'x' => 'excludes',
                'w' => 'within'
        };
        return operatorCodes;
    }

    @NamespaceAccessible public static Map<String, String[]> getTypeToOps(){
        Map<String, String[]> type2ops = new Map<String, String[]> {
                'REFERENCE' => new String[]{'e', 'n'},
                'ID' => new String[]{'e', 'n'},
                'STRING' => new String[]{'e', 'n', 's', 'c', 'k'},
                'PICKLIST' => new String[]{'e', 'n', 's', 'c', 'k'},
                'PERCENT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DOUBLE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'BOOLEAN' => new String[]{'e', 'n'},
                'TEXTAREA' => new String[]{'e', 'n', 's', 'c', 'k'},
                'DATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DATETIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                //'MULTIPICKLIST' => new String[]{'e', 'n', 'u', 'x'},
                'ANYTYPE' => new String[]{'e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w'},
                'BASE64BINARY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'INTEGER' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'INT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'TIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'ADDRESS' => new String[]{'w', 'y'},
                'ADDRESSCOUNTRY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'ADDRESSSTATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'AUTONUMBER' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'BIRTHDAY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'BITVECTOR' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'CONTENT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'CURRENCY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'CURRENCYCODE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'DATACATEGORYGROUPREFERENCE' => new String[]{'e', 'n'},
                'DATEONLY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DIVISION' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'DUEDATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DYNAMICENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'EMAIL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'ENCRYPTEDTEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'ENTITYID' => new String[]{'e', 'n', 's'},
                'ENUMORID' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'EXTERNALID' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'FAX' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'HTMLMULTILINETEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'HTMLSTRINGPLUSCLOB' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'INETADDRESS' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'LOCATION' => new String[]{'w', 'y'},
                'MULTIENUM' => new String[]{'e', 'n', 'u', 'x'},
                'MULTILINETEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'PHONE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'RECORDTYPE' => new String[]{'e', 'n'},
                'SFDCENCRYPTEDTEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'SIMPLENAMESPACE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'STATICENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'STRINGPLUSCLOB' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'TEXT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'TEXTENUM' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'TIMEONLY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'URL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'}
        };
        return type2ops;
    }

    @NamespaceAccessible public static Map<String, String[]> getOperatorsByDisplayType(){
        Map<String, String[]> type2ops = new Map<String, String[]> {
                'REFERENCE' => new String[]{'e', 'n'},
                'ID' => new String[]{'e', 'n'},
                'STRING' => new String[]{'e', 'n', 's', 'c', 'k'},
                'COMBOBOX' => new String[]{'e', 'n', 's', 'c', 'k'},
                'PICKLIST' => new String[]{'e', 'n', 's', 'c', 'k'},
                'PERCENT' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DOUBLE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'LONG' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'BOOLEAN' => new String[]{'e', 'n'},
                'TEXTAREA' => new String[]{'e', 'n', 's', 'c', 'k'},
                'DATE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DATETIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'MULTIPICKLIST' => new String[]{'e', 'n', 'u', 'x'},
                'ANYTYPE' => new String[]{'e', 'n', 's', 'c', 'k', 'l', 'g', 'm', 'n', 'h', 'u', 'x', 'w'},
                'BASE64' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'INTEGER' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'TIME' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'ADDRESS' => new String[]{'w', 'y'},
                'CURRENCY' => new String[]{'e', 'n', 'l', 'g', 'm', 'h'},
                'DATACATEGORYGROUPREFERENCE' => new String[]{'e', 'n'},
                'EMAIL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'ENCRYPTEDSTRING' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'PHONE' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'},
                'URL' => new String[]{'e', 'n', 'l', 'g', 'm', 'h', 'c', 'k', 's', 'i'}
        };
        return type2ops;
    }
}