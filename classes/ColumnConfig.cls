/**
 * This class is used as a wrapper by DynamicDatatableController
 */
public with sharing class ColumnConfig {
    @AuraEnabled
    public String actions;
    @AuraEnabled
    public CellAttributes cellAttributes;
    @AuraEnabled
    public Boolean editable;
    @AuraEnabled
    public String fieldName;
    @AuraEnabled
    public Integer fixedWidth;
    @AuraEnabled
    public Boolean hideDefaultActions;
    @AuraEnabled
    public String iconName;
    @AuraEnabled
    public String initialWidth;
    @AuraEnabled
    public String label;
    @AuraEnabled
    public String sortable;
    @AuraEnabled
    public String type;
    @AuraEnabled
    public TypeAttributes typeAttributes;
    @AuraEnabled
    public Boolean wrapText;

    // private final static Set<DisplayType> EDITABLE_TYPES = new Set<DisplayType>{ DisplayType.DOUBLE, DisplayType.PERCENT, DisplayType.STRING };

    private Map<DisplayType, String> formattingTypesByFieldType = new Map<DisplayType, String>{
        DisplayType.BOOLEAN => 'boolean',
        DisplayType.COMBOBOX => 'text',
        DisplayType.CURRENCY => 'currency',
        DisplayType.DATE => 'date',
        DisplayType.DATETIME => 'date',
        DisplayType.CURRENCY => 'currency',
        DisplayType.DOUBLE => 'number',
        DisplayType.EMAIL => 'url',
        DisplayType.ID => 'text',
        DisplayType.INTEGER => 'number',
        DisplayType.LONG => 'number',
        DisplayType.MULTIPICKLIST => 'text',
        DisplayType.PERCENT => 'percent',
        DisplayType.PHONE => 'phone',
        DisplayType.PICKLIST => 'text',
        DisplayType.STRING => 'text',
        DisplayType.TEXTAREA => 'text',
        DisplayType.TIME => 'date',
        DisplayType.URL => 'url'
    };

    // CTOR

    public ColumnConfig(FieldSetMember field, Boolean hideDefaultActions) {
        initColumnConfig(field);
        this.hideDefaultActions = hideDefaultActions;
    }

    // PRIVATE

    private void initColumnConfig(FieldSetMember field) {
        String fieldPath = field.getFieldPath();
        label = fieldPath.contains('.') ? getRelationalLabel(fieldPath) : field.getLabel();

        // TODO: Handle other non-name fields like CaseNumber
        if (fieldPath == 'Name' || fieldPath.substringAfter('.') == 'Name') {
            fieldName = fieldPath.replace('Name', 'LinkName');
            type = 'url';
        } else {
            fieldName = fieldPath;
            DisplayType fieldType = field.getType();
            type = formattingTypesByFieldType.get(fieldType);
            // NOTE: By making a column editable, the show-row-number-column attribute is always true and the number column is displayed
            // so we do not set any editable column for now, besides editable rows logic is not implemented yet
            // editable = EDITABLE_TYPES.contains(fieldType);
        }

        if (type == 'url') {
            cellAttributes = new CellAttributes();
            typeAttributes = new TypeAttributes(fieldPath);
        }
    }

    private String getRelationalLabel(String fieldPath) {
        // TODO: currently using field sets, only one parent level is allowed,
        // but this is not really accurate, it should be a recursive method (since there may be multiple levels)
        // TODO: retrieving proper labels for each relationship until the last field, otherwise there will be an
        // issue if api name does not correspond to label

        String result = fieldPath.replace('__r', '').replace('__c', '').replace('.', ' ').replace('_', ' ');
        result = String.join(result.splitByCharacterTypeCamelCase(), ' ');
        return result;
    }

    // INNER

    private class TypeAttributes {
        @AuraEnabled
        public Label label;
        @AuraEnabled
        public String target;

        // CTOR

        public TypeAttributes(String fieldName) {
            label = new Label(fieldName);
            target = '_top';
        }
    }

    private class Label {
        @AuraEnabled
        public String fieldName;

        // CTOR

        public Label(String fieldName) {
            this.fieldName = fieldName;
        }
    }

    private class CellAttributes {
        @AuraEnabled
        public String alignment;

        // CTOR

        public CellAttributes() {
            alignment = 'left';
        }
    }
}