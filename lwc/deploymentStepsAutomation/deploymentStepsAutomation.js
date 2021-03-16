import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { showToastError } from 'c/copadocoreToastNotification';

import DATA_JSON_FIELD from '@salesforce/schema/Step__c.dataJson__c';
import NAME_FIELD from '@salesforce/schema/Deployment__c.Name';

import Automation from '@salesforce/label/c.AUTOMATION';

export default class DeploymentStepsAutomation extends LightningElement {
    label = {
        Automation
    };

    @api currentDeploymentId;
    @api stepId;

    filterFormattingParameters;

    selectedAutomation;
    _originalSelectedAutomationId;

    // This variables are used to reset edited step information to the original value if modal is closed
    _originalSelectedAutomation;

    connectedCallback() {
        // Since changes inside of an array are not detected, we need to assign
        // the entire array once all variables that it stores are already initialized
        this.filterFormattingParameters = [this.currentDeploymentId];
    }

    // If stepId changes to actually be another valid step Id, the wiredStep is called again
    // but if it is not actually an id, then wiredStep is not called
    @wire(getRecord, { recordId: '$stepId', fields: [DATA_JSON_FIELD] })
    wiredStep(value) {
        const { data, error } = value;
        if (data) {
            this.selectedAutomation = this._originalSelectedAutomation = undefined;
            this.parseDataIntoVariables(data);
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
        }
    }

    parseDataIntoVariables(data) {
        const dataJsonValueObject = JSON.parse(getFieldValue(data, DATA_JSON_FIELD));
        this._originalSelectedAutomationId = dataJsonValueObject.automationId;
    }

    // If _originalSelectedAutomationId changes to actually be another valid automation Id, the wiredOriginalAutomation is called again
    // but if it is not actually an id, then it wiredOriginalAutomation is not called
    @wire(getRecord, { recordId: '$_originalSelectedAutomationId', fields: [NAME_FIELD] })
    wiredOriginalAutomation(value) {
        const { data, error } = value;
        if (data) {
            this.selectedAutomation = this._originalSelectedAutomation = {
                Id: this._originalSelectedAutomationId,
                Name: getFieldValue(data, NAME_FIELD)
            };
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this.selectedAutomation = undefined;
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.recordId) {
            this.selectedAutomation = { Id: lookupData.detail.recordId, Name: lookupData.detail.recordName };
        } else {
            this.selectedAutomation = undefined;
        }
    }

    @api
    getFieldsToSave() {
        const fields = {};
        fields[DATA_JSON_FIELD.fieldApiName] = JSON.stringify(this.generateDataJasonFieldValue());
        return fields;
    }

    generateDataJasonFieldValue() {
        return {
            automationId: this.selectedAutomation ? this.selectedAutomation.Id : ''
        };
    }

    @api
    restoreOriginalValues() {
        this.selectedAutomation = this._originalSelectedAutomation;
    }
}