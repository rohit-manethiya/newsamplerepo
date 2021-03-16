import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import { showToastError } from 'c/copadocoreToastNotification';

import DATA_JSON_FIELD from '@salesforce/schema/Step__c.dataJson__c';
import NAME_FIELD from '@salesforce/schema/External_CI_Job__c.Name';

import EXTERNAL_CI_JOB from '@salesforce/label/c.EXTERNAL_CI_JOB';

export default class DeploymentStepsExternalCI extends LightningElement {
    label = {
        EXTERNAL_CI_JOB
    };

    @api stepId;

    selectedExternalCIJob;
    _originalSelectedExternalCIJobId;

    // This variables are used to reset edited step information to the original value if modal is closed
    _originalSelectedExternalCIJob;

    // If stepId changes to actually be another valid step Id, the wiredStep is called again
    // but if it is not actually an Id, then wiredStep is not called
    @wire(getRecord, { recordId: '$stepId', fields: DATA_JSON_FIELD })
    wiredStep(value) {
        const { data, error } = value;
        this.selectedExternalCIJob = this._originalSelectedExternalCIJob = undefined;
        if (data) {
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
        this._originalSelectedExternalCIJobId = dataJsonValueObject.xciJobId;
    }

    // If _originalSelectedExternalCIJobId changes to actually be another valid automation Id, the wiredOriginalExternalCIJob is called again
    // but if it is not actually an id, then it wiredOriginalExternalCIJob is not called
    @wire(getRecord, { recordId: '$_originalSelectedExternalCIJobId', fields: [NAME_FIELD] })
    wiredOriginalExternalCIJob(value) {
        const { data, error } = value;
        if (data) {
            this.selectedExternalCIJob = this._originalSelectedExternalCIJob = {
                Id: this._originalSelectedExternalCIJobId,
                Name: getFieldValue(data, NAME_FIELD)
            };
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this.selectedExternalCIJob = undefined;
        }
    }

    getSelectedId(lookupData) {
        if (lookupData.detail.recordId) {
            this.selectedExternalCIJob = { Id: lookupData.detail.recordId, Name: lookupData.detail.recordName };
        } else {
            this.selectedExternalCIJob = undefined;
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
            xciJobId: this.selectedExternalCIJob ? this.selectedExternalCIJob.Id : ''
        };
    }

    @api
    restoreOriginalValues() {
        this.selectedExternalCIJob = this._originalSelectedExternalCIJob;
    }
}