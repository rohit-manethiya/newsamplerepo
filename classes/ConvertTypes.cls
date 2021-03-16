/**
 * Dynamic input value conversion according to desired field soap type
 * @author Mert YALTI
 * @since 26/07/2018
 * @version 1.0
 * @see  SoapType
 * @see  SObject
 * @see  SobjectField
 * @see  SObjectType
 * @see  DisplayTypes
 */
public with sharing class ConvertTypes {

    final SObjectField field;
    final ITypeConverter converter;
    /**
     * Constructer method to define SoapType and proper converter class
     * @param  field Sobjectfield which we will use for defining SoapType to convert input value
     * @return       N/A
     */
    public ConvertTypes(SObjectField field) {
        this.field = field;
        SoapType nsoapType = field.getDescribe().getSoapType();
        try {
            if(nsoapType == SoapType.DOUBLE && field.getDescribe().getScale() == 0) {
                this.converter = (ITypeConverter) IntegerConverter.class.newInstance();
            } else {
                this.converter = (ITypeConverter) converters.get(nsoapType).newInstance();
            }

        } catch(Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Converter not found ==>' + ex.getMessage());
        }
    }
    /**
     * Populates given field with properly converted input value
     * @param  record The record we are populating its fields
     * @param  input  The value that we use for populated given field on given record
     * @return        Updated sObject
     */
    public SObject putTo(SObject record, String input) {
        record.put(field, converter.getValue(input));
        return record;
    }
    /**
     * Static map to collect SoapTypes (primitive types) with their converter classes
     */
    static final Map<SoapType, Type> converters = new Map<SoapType, Type>{
            SoapType.DOUBLE => DoubleConverter.class,
            SoapType.BASE64BINARY => BlobConverter.class,
            SoapType.DATE => DateConverter.class,
            SoapType.DATETIME => DateTimeConverter.class,
            SoapType.BOOLEAN => BooleanConverter.class,
            SoapType.ID => StringConverter.class,
            SoapType.STRING => StringConverter.class,
            SoapType.INTEGER => IntegerConverter.class
    };
    /**
     * Converts given string to double
     * @see ITypeConverter
     */
    public class DoubleConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return Double.valueOf(input);
        }
    }
    /**
     * Converts given string to date
     * @see ITypeConverter
     */
    public class DateConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return Date.valueOf(input);
        }
    }
    /**
     * Converts given string to datetime
     * @see ITypeConverter
     */
    public class DateTimeConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return Datetime.valueOf(input);
        }
    }
    /**
     * Converts given string to boolean
     * @see ITypeConverter
     */
    public class BooleanConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return false;
            }
            if(input == '0') {
                return false;
            } else if(input == '1') {
                return true;
            } else {
                return Boolean.valueOf(input);
            }
        }
    }
    /**
     * Converts given string to string
     * String to string may seem not necessary but the architecture requires a converter for each soap type
     * @see ITypeConverter
     */
    public class StringConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return String.valueOf(input);
        }
    }
    /**
     * Converts given string to integer
     * @see ITypeConverter
     */
    public class IntegerConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return Integer.valueOf(input);
        }
    }
    /**
     * Converts given string to base64 (Blob)
     * This is probably the most sensitive one so in case of converter issues eleminate this posibilty first to save some time
     * @see ITypeConverter
     */
    public class BlobConverter implements ITypeConverter {
        public Object getValue(String input) {
            if(String.isBlank(input)) {
                return null;
            }
            return Blob.valueOf(input);
        }
    }
}