public with sharing class QueryEditor {

    public String queryJson { get; set; }
    public SoqlWrapper queryWrapper { get; set; }

    /**
     * Criteria wrapper will be used to hold values for each filter criteria are entered at query editor component
     * Note: operatorSet is Selectoption and selectoption is not serializable. You have to clear values before serialize. Editor has capability of auto populate from JSON.
     */
    public class CriteriaWrapper {
        public String fieldName { get; set; }
        public String fieldType { get; set; }
        public Integer order { get; set; }
        public String operator { get; set; }
        public List<SelectOption> operatorSet { get; set; }
        public String input { get; set; }
        public Double numberInput { get; set; }
        public Date dateInput { get; set; }
        public Datetime dateTimeInput { get; set; }
        public String finalValue { get; set; }

        public CriteriaWrapper() {
            this.fieldName = '--None--';
            this.fieldType = 'STRING';
            this.operator = '--None--';
            this.operatorSet = new List<SelectOption>();
            this.input = '';
            this.numberInput = 0;
            this.dateInput = null;
            this.dateTimeInput = null;
            this.finalValue = '';
        }

        public String getFieldName() {
            return this.fieldName;
        }

        public void setFieldName(String fieldName) {
            this.fieldName = fieldName;
        }

        public String getFieldType() {
            return this.fieldType;
        }

        public void setFieldType(String fieldType) {
            this.fieldType = fieldType;
        }

        public Integer getOrder() {
            return this.order;
        }

        public void setOrder(Integer order) {
            this.order = order;
        }

        public String getOperator() {
            return this.operator;
        }

        public void setOperator(String operator) {
            this.operator = operator;
        }

        public List<SelectOption> getOperatorSet() {
            return this.operatorSet;
        }

        public void setOperatorSet(List<SelectOption> operatorSet) {
            this.operatorSet = operatorSet;
        }

        public String getInput() {
            return this.input;
        }

        public void setInput(String input) {
            this.input = input;
        }

        public Date getDateInput() {
            return this.dateInput;
        }

        public void setDateInput(Date dateInput) {
            this.dateInput = dateInput;
        }

        public Datetime getDateTimeInput() {
            return this.dateTimeInput;
        }

        public void setDateTimeInput(Datetime dateTimeInput) {
            this.dateTimeInput = dateTimeInput;
        }

        public Decimal getNumberInput() {
            return this.numberInput;
        }

        public void setNumberInput(Decimal numberInput) {
            this.numberInput = numberInput;
        }

        public String getFinalValue() {
            return this.finalValue;
        }

        public void setFinalValue(String finalValue) {
            this.finalValue = finalValue;
        }
    }

    /**
     * Summarize By wrapper will hold the field and operator to make progress at kanban board
     */
    public class SummarizeByWrapper {
        public String fieldName { get; set; }
        public String operatorName { get; set; }
        public Integer order { get; set; }

        public SummarizeByWrapper() {
            this.fieldName = '';
            this.operatorName = '';
        }
    }

    /**
     * SoqlWrapper is used to hold all query editor values are entered are entered at query editor component
     */
    public class SoqlWrapper {
        public String viewName { get; set; }
        public List<String> selectedFields { get; set; }
        public List<String> selectedFooterFields { get; set; }
        public List<SummarizeByWrapper> summarizeByList { get; set; }
        public List<CriteriaWrapper> criteriaList { get; set; }
        public List<String> orderByList { get; set; }
        public String queryLimit { get; set; }
        public String wholeSoql { get; set; }
        public String fieldToReadUpdate { get; set; }
        public String headerField { get; set; }
        public String orderedIn { get; set; }
        public String nullValues { get; set; }
        public String sobjectTypeName { get; set; }
        public Boolean enableFilterLogic { get; set; }
        public String filterLogic { get; set; }
        public String kanbanDescription { get; set; }
        public String userImageField { get; set; }
        public String colorField { get; set; }
        public Map<String, ColumnFilter> columnMap { get; set; }

        public SoqlWrapper() {
            this.viewName = '';
            this.selectedFields = null;
            this.selectedFooterFields = null;
            this.summarizeByList = new List<SummarizeByWrapper>();
            this.criteriaList = new List<CriteriaWrapper>();
            this.orderByList = null;
            this.queryLimit = '200';
            this.wholeSoql = 'SELECT {0} FROM {1}';
            this.fieldToReadUpdate = '';
            this.headerField = '';
            this.orderedIn = '';
            this.nullValues = '';
            this.sobjectTypeName = '';
            this.enableFilterLogic = false;
            this.filterLogic = '';
            this.kanbanDescription = '';
            this.userImageField = '';
            this.colorField = '';
            this.columnMap = new Map<String, ColumnFilter>();
        }
    }

    /**
     * This is used to add optional information to the kanban column such as; add/remove or order column
     */
    public class ColumnFilter {
        public Boolean isSelected { get; set; }
        public String columnValue { get; set; }
        public Integer orderNumber { get; set; }

        public ColumnFilter(String cValue, Integer oNumber) {
            this.isSelected = true;
            this.columnValue = cValue;
            this.orderNumber = oNumber;
        }
    }
}