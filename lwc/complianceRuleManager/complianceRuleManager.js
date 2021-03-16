import { LightningElement, api, track } from 'lwc';

import getComplianceFileFromBackend from '@salesforce/apex/ComplianceRuleManagerCtrl.getComplianceFileFromBackend';
import saveCriterias from '@salesforce/apex/ComplianceRuleManagerCtrl.saveCriterias';
import deleteCriterias from '@salesforce/apex/ComplianceRuleManagerCtrl.deleteCriterias';
import criteriasOfRule from '@salesforce/apex/ComplianceRuleManagerCtrl.criteriasOfRule';
import hasComplianceRuleFLS from '@salesforce/apex/ComplianceRuleManagerCtrl.hasComplianceRuleFLS';
import isComplianceHubEnabled from '@salesforce/apex/FeatureHelper.isComplianceHubEnabled';
import isCCHEnabled from '@salesforce/apex/LicenseHelper.isCCHEnabled';

import COMPLIANCE_RULE_MISSING_FLS from '@salesforce/label/c.COMPLIANCE_RULE_MISSING_FLS';
import FEATURE_NOT_SUPPORTED from '@salesforce/label/c.FEATURE_NOT_SUPPORTED';
import CCH_LICENSE_NOT_ENABLED from '@salesforce/label/c.CCH_LICENSE_NOT_ENABLED';
import CCH_CRITERIA_SECTION_TITLE from '@salesforce/label/c.CCH_CRITERIA_SECTION_TITLE';
import CCH_METADATA_TYPE_PARAMETER from '@salesforce/label/c.CCH_METADATA_TYPE_PARAMETER';
import CCH_NODE_PARAMETER from '@salesforce/label/c.Node';
import CCH_FIELD_PARAMETER from '@salesforce/label/c.Field';
import CCH_OPERATOR_PARAMETER from '@salesforce/label/c.Operator';
import CCH_VALUE_PARAMETER from '@salesforce/label/c.VALUE';
import CCH_RESET from '@salesforce/label/c.RESET';
import CCH_SAVE from '@salesforce/label/c.CCH_SAVE';
import CCH_NEW_ROW from '@salesforce/label/c.CCH_NEW_ROW';
import CCH_CRITERIA_LOGIC from '@salesforce/label/c.CCH_CRITERIA_LOGIC';

import COMPLIANCE_RULE from '@salesforce/schema/Compliance_Rule__c';
import COMPLIANCE_RULE_METADATA_TYPE from '@salesforce/schema/Compliance_Rule__c.Metadata_Type__c';
import COMPLIANCE_RULE_CRITERIA_LOGIC from '@salesforce/schema/Compliance_Rule__c.Filter_Criteria__c';
import COMPLIANCE_RULE_CRITERIA from '@salesforce/schema/Compliance_Rule_Criteria__c';
import COMPLIANCE_CRITERIA_TEXT from '@salesforce/schema/Compliance_Rule_Criteria__c.Criteria__c';
import COMPLIANCE_CRITERIA_ORDER from '@salesforce/schema/Compliance_Rule_Criteria__c.Order__c';
import COMPLIANCE_CRITERIA_NODE from '@salesforce/schema/Compliance_Rule_Criteria__c.Node__c';
import COMPLIANCE_CRITERIA_FIELD from '@salesforce/schema/Compliance_Rule_Criteria__c.Field__c';
import COMPLIANCE_CRITERIA_FIELD_TYPE from '@salesforce/schema/Compliance_Rule_Criteria__c.Field_Type__c';
import COMPLIANCE_CRITERIA_OPERATOR from '@salesforce/schema/Compliance_Rule_Criteria__c.Operator__c';
import COMPLIANCE_CRITERIA_VALUE from '@salesforce/schema/Compliance_Rule_Criteria__c.Value__c';

import Graph from './Graph';
import { type2ops, operatorCodes } from './OperatorsUtils';

export default class ComplianceRuleManager extends LightningElement {
    @api recordId;

    @track metadataTypes = [];
    @track nodeList = [];
    @track criterias = [];

    labels = {
        CCH_CRITERIA_SECTION_TITLE,
        CCH_METADATA_TYPE_PARAMETER,
        CCH_NODE_PARAMETER,
        CCH_FIELD_PARAMETER,
        CCH_OPERATOR_PARAMETER,
        CCH_VALUE_PARAMETER,
        CCH_RESET,
        CCH_SAVE,
        CCH_NEW_ROW,
        CCH_CRITERIA_LOGIC
    };
    switchIconName = 'utility:chevrondown';
    metadataTypeSelected = '';
    isLoading = false;
    criteriaLogic = '';

    get isMetadataSelected() {
        return this.metadataTypeSelected !== '';
    }

    _graph;
    _legacyCriterias = [];
    _criteriasToDeleteSObjectList = [];
    _emptyCriteria = {
        Id: 1,
        node: '',
        field: '',
        operator: '',
        value: '',
        fieldList: [],
        operatorList: [],
        valueType: 'STRING',
        valueBoxType: 'text',
        isBoolean: false,
        valueCheckboxValue: false,
        sfId: ''
    };

    constructor() {
        super();
        this._init();
    }

    // PUBLIC

    handleMetadataTypeChange(event) {
        if (this.metadataTypes.length > 0) {
            this.metadataTypeSelected = event.detail.value;
            this.nodeList = this._getNodeList(this.metadataTypeSelected);
        }
    }

    handleNodeChange(event) {
        if (this.nodeList) {
            const selectedNode = event.detail.value;
            this.nodeList = this._filterNodeListByNode(this.nodeList, selectedNode);

            const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
            criteria.node = selectedNode;
            criteria.fieldList = this._getFieldList(selectedNode);
        }
    }

    handleFieldChange(event) {
        const selectedField = event.detail.value;
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);

        criteria.field = selectedField;
        criteria.valueType = this._graph.getEdge(selectedField, criteria.node)[0].target.name.toUpperCase();
        criteria.operatorList = this._getOperatorList(criteria.valueType);
        criteria.valueBoxType = this._getValueBoxType(criteria.valueType);
        criteria.isBoolean = criteria.valueBoxType === 'checkbox';
    }

    handleOperatorChange(event) {
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
        criteria.operator = event.detail.value;
    }

    handleValueChange(event) {
        const criteria = this.criterias.find((criteriaItem) => criteriaItem.Id === +event.target.dataset.criteriaId);
        let value;
        if (criteria.valueBoxType === 'checkbox') {
            value = `${event.detail.checked}`;
            criteria.valueCheckboxValue = event.detail.checked;
        } else {
            value = event.detail.value;
        }

        criteria.value = value;
    }

    handleCriteriaLogicChange(event) {
        this.criteriaLogic = event.target.value;
    }

    changeExpandableSection() {
        this.template.querySelector('div[data-id="RuleManagerAccordion"]').classList.toggle('slds-is-open');
        this.switchIconName = this.switchIconName === 'utility:chevronright' ? 'utility:chevrondown' : 'utility:chevronright';
    }

    addEmptyCriteria() {
        const criteria = JSON.parse(JSON.stringify(this._emptyCriteria));
        criteria.Id = this.criterias.length + 1;
        this.criterias.push(criteria);
    }

    removeCriteria(event) {
        if (this.criterias.length === 1) {
            this.nodeList = this._getNodeList(this.metadataTypeSelected);
            this.criterias = [JSON.parse(JSON.stringify(this._emptyCriteria))];
        } else if (this.criterias.length > 1) {
            const selectedCriteriaId = +event.target.dataset.criteriaId;
            const selectedCriteria = this.criterias.find((criteriaItem) => criteriaItem.Id === selectedCriteriaId);

            if (selectedCriteria.sfId) {
                this._criteriasToDeleteSObjectList.push({
                    sObjectType: COMPLIANCE_RULE_CRITERIA.objectApiName,
                    Id: selectedCriteria.sfId
                });
            }

            this._legacyCriterias = this._legacyCriterias.filter((criteria) => criteria.Id !== selectedCriteria.sfId);
            this.criterias = this.criterias.filter((criteria) => criteria.Id !== selectedCriteriaId);
            this.criterias = this.criterias.map((criteria, index) => {
                criteria.Id = index + 1;
                return criteria;
            });
        }
    }

    async save() {
        this.isLoading = true;

        this.criteriaLogic = this._getUpdatedLogic(this.criteriaLogic, this.criterias);

        const criteriaRecordsSFShape = this.criterias.map((criteria, index) => {
            if (criteria.valueBoxType === 'checkbox' && !criteria.value) {
                criteria.value = 'false';
            }

            let formatedValue = criteria.value ? criteria.value.trim() : criteria.value;
            if (criteria.operator.toLowerCase() === 'within' || criteria.operator.toLowerCase() === 'excludes') {
                formatedValue = `[${formatedValue}]`;
            }

            const criteriaString = `${criteria.node}.${criteria.field}<${criteria.operator.replace(/ /g, '').toUpperCase()}>${formatedValue}`;

            const result = {
                sObjectType: COMPLIANCE_RULE_CRITERIA.objectApiName
            };

            result[COMPLIANCE_RULE.objectApiName] = this.recordId;
            result[COMPLIANCE_CRITERIA_TEXT.fieldApiName] = criteriaString;
            result[COMPLIANCE_CRITERIA_ORDER.fieldApiName] = index + 1;
            result[COMPLIANCE_CRITERIA_NODE.fieldApiName] = criteria.node;
            result[COMPLIANCE_CRITERIA_FIELD.fieldApiName] = criteria.field;
            result[COMPLIANCE_CRITERIA_FIELD_TYPE.fieldApiName] = criteria.valueType;
            result[COMPLIANCE_CRITERIA_OPERATOR.fieldApiName] = criteria.operator;
            result[COMPLIANCE_CRITERIA_VALUE.fieldApiName] = formatedValue;

            if (criteria.sfId) {
                result.Id = criteria.sfId;
            }

            return result;
        });

        try {
            if (this._criteriasToDeleteSObjectList.length > 0) {
                await deleteCriterias({
                    criterias: this._criteriasToDeleteSObjectList
                });
            }

            await saveCriterias({
                criteria: criteriaRecordsSFShape,
                criteriaLogic: this.criteriaLogic,
                metadataType: this.metadataTypeSelected
            });

            await this._loadLegacyCriterias();
        } catch (e) {
            console.log(e);
        }

        this.isLoading = false;
    }

    resetData() {
        this.metadataTypeSelected = '';
        this.nodeList = this._getNodeList(this.metadataTypeSelected);
        this.criterias = [JSON.parse(JSON.stringify(this._emptyCriteria))];
        this._legacyCriterias.forEach((criteria) => {
            this._criteriasToDeleteSObjectList.push({
                sObjectType: COMPLIANCE_RULE_CRITERIA.objectApiName,
                Id: criteria.Id
            });
        });
    }

    // PRIVATE

    async _init() {
        this.isLoading = true;

        this.criterias = [JSON.parse(JSON.stringify(this._emptyCriteria))];

        const hasFlsPermissions = await hasComplianceRuleFLS();
        const complianceHubEnabled = await isComplianceHubEnabled();
        const cchEnabled = await isCCHEnabled();

        // @TODO: Errors will be properly showed in US-0019288
        if (!hasFlsPermissions) {
            throw new Error(COMPLIANCE_RULE_MISSING_FLS);
        } else if (!complianceHubEnabled) {
            throw new Error(FEATURE_NOT_SUPPORTED);
        } else if (!cchEnabled) {
            throw new Error(CCH_LICENSE_NOT_ENABLED);
        }

        this._graph = await this._getComplianceGraph();
        this.metadataTypes = await this._getMetadataTypeOptions();
        await this._loadLegacyCriterias();

        this.isLoading = false;
    }

    async _getComplianceGraph() {
        let complianceFileAsString = await getComplianceFileFromBackend();
        const complianceJSON = JSON.parse(complianceFileAsString);

        let result = new Graph();
        result.importJson(complianceJSON);

        return result;
    }

    async _loadLegacyCriterias() {
        const existingCriteria = [];

        this._legacyCriterias = await criteriasOfRule({
            ruleId: this.recordId
        });

        if (this._legacyCriterias.length > 0) {
            try {
                this.metadataTypeSelected = this._legacyCriterias[0][COMPLIANCE_RULE.objectApiName.replace('__c', '__r')][
                    COMPLIANCE_RULE_METADATA_TYPE.fieldApiName
                ];

                this.criteriaLogic = this._legacyCriterias[0][COMPLIANCE_RULE.objectApiName.replace('__c', '__r')][
                    COMPLIANCE_RULE_CRITERIA_LOGIC.fieldApiName
                ];

                this._legacyCriterias.forEach((criteria) => {
                    this.criteriaLogic = this.criteriaLogic.replace(criteria.Name, criteria.Order__c);
                });

                this.nodeList = this._getNodeList(this.metadataTypeSelected);

                this._legacyCriterias.forEach((legacyCriteria, index) => {
                    const node = legacyCriteria[COMPLIANCE_CRITERIA_NODE.fieldApiName];
                    const field = legacyCriteria[COMPLIANCE_CRITERIA_FIELD.fieldApiName];
                    const operator = legacyCriteria[COMPLIANCE_CRITERIA_OPERATOR.fieldApiName].toLowerCase();
                    const value = legacyCriteria[COMPLIANCE_CRITERIA_VALUE.fieldApiName];
                    const valueType = legacyCriteria[COMPLIANCE_CRITERIA_FIELD_TYPE.fieldApiName];

                    this.nodeList = this._filterNodeListByNode(this.nodeList, node);

                    existingCriteria.push({
                        Id: index + 1,
                        node,
                        field,
                        operator,
                        value,
                        fieldList: this._getFieldList(node),
                        operatorList: this._getOperatorList(valueType),
                        valueType,
                        valueBoxType: this._getValueBoxType(valueType),
                        valueCheckboxValue: this._getValueBoxType(valueType) === 'checkbox' ? value === 'true' : false,
                        isBoolean: this._getValueBoxType(valueType) === 'checkbox',
                        sfId: legacyCriteria.Id
                    });
                });

                this.criterias = JSON.parse(JSON.stringify(existingCriteria));
            } catch (e) {
                console.log(e);
            }
        } else {
            this.criterias = [JSON.parse(JSON.stringify(this._emptyCriteria))];
        }
    }

    async _getMetadataTypeOptions() {
        let result = this._graph.getRootNodes().map((rootNode) => {
            return { label: rootNode.name, value: rootNode.name };
        });

        return this._sortComboboxList(result);
    }

    _getNodeList(metadataType) {
        let result = [];
        if (metadataType) {
            result = this._graph.getRootEdges(metadataType).map((edge) => {
                return { label: edge.label, value: edge.label };
            });
            result = this._sortComboboxList(result);
        }
        return result;
    }

    _getFieldList(node) {
        let result = this._graph.getLeafEdges(node).map((edge) => {
            return { label: edge.label, value: edge.label };
        });
        return this._sortComboboxList(result);
    }

    _getOperatorList(fieldType) {
        let result = [];
        if (Object.hasOwnProperty.call(type2ops, fieldType)) {
            result = type2ops[fieldType];
        }

        result = result.map((operatorType) => operatorCodes[operatorType]);

        return result.map((operatorType) => {
            return { label: operatorType, value: operatorType };
        });
    }

    _getValueBoxType(operator) {
        const result = {
            DATE: 'date',
            DATETIME: 'datetime',
            INTEGER: 'number',
            DOUBLE: 'number',
            INT: 'number',
            PERCENT: 'number',
            BOOLEAN: 'checkbox'
        };

        return result[operator] || 'text';
    }

    _filterNodeListByNode(nodeList, selectedNode) {
        let result = nodeList;
        if (selectedNode !== 'name') {
            result = result.filter((node) => node.label === 'name' || node.label === selectedNode);
        }
        return result;
    }

    _sortComboboxList = (list) => list.sort((x, y) => x.label?.localeCompare(y.label));

    _getUpdatedLogic(logic, criterias) {
        criterias.forEach((criteria, index) => {
            const row = (index + 1).toString();

            if (
                !criteria.sfId &&
                !logic
                    .replace(/\(|\)/g, '')
                    .replace(/AND|OR/g, '')
                    .split(' ')
                    .includes(row)
            ) {
                if (index === 0) {
                    logic += row;
                } else {
                    logic += ' AND ' + row;
                }
            }
        });

        return logic;
    }
}