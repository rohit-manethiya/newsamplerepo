import { LightningElement, api } from 'lwc';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

import { showToastSuccess } from 'c/copadocoreToastNotification';
import { autoFormValidation, handleAsyncError } from 'c/copadocoreUtils';

import STEP_OBJECT from '@salesforce/schema/Step__c';
import ID_FIELD from '@salesforce/schema/Step__c.Id';
import NAME_FIELD from '@salesforce/schema/Step__c.Name';
import TYPE_FIELD from '@salesforce/schema/Step__c.Type__c';
import DEPLOYMENT_FIELD from '@salesforce/schema/Step__c.Deployment__c';

import Cancel from '@salesforce/label/c.Cancel';
import Save from '@salesforce/label/c.Save';
import STEP_NAME from '@salesforce/label/c.STEP_NAME';
import Step_Type from '@salesforce/label/c.Step_Type';
import Step_Details from '@salesforce/label/c.Step_Details';
import Create_Record_Error_Title from '@salesforce/label/c.Create_Record_Error_Title';
import Update_Record_Error_Title from '@salesforce/label/c.Update_Record_Error_Title';
import Step_Saved from '@salesforce/label/c.Step_Saved';

export default class DeploymentStepsDetails extends LightningElement {
    label = {
        Cancel,
        Save,
        STEP_NAME,
        Step_Type,
        Step_Details,
        Create_Record_Error_Title,
        Update_Record_Error_Title,
        Step_Saved
    };

    @api currentDeploymentId;
    @api selectedStepId;
    @api selectedStepName;
    @api selectedStepType;

    showSpinner;

    // If public property has not a provided value from the parent component
    // it means that the step is being created
    get isCreation() {
        return this.selectedStepId ? false : true;
    }

    get detailsCardTitle() {
        return `${this.selectedStepType} ${this.label.Step_Details}`;
    }

    inputStepName;
    get stepName() {
        return this.selectedStepName ? this.selectedStepName : this.inputStepName;
    }

    get isApex() {
        return this.selectedStepType === 'Apex';
    }

    get isSalesforceFlow() {
        return this.selectedStepType === 'Salesforce Flow';
    }

    get isExternalCI() {
        return this.selectedStepType === 'External CI';
    }

    /*get isAutomation() {
        return this.selectedStepType === 'Automation';
    }*/

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    @api async handleSave() {
        this.showSpinner = true;

        const childStepElement = this.childStepElement();
        const isChildFormValidated = childStepElement.getAutoFormValidation ? childStepElement.getAutoFormValidation() : true;
        const isFormValidated = autoFormValidation(this.template, this);
        if (isFormValidated && isChildFormValidated) {
            let fields = {};
            if (childStepElement.getFieldsToSave) {
                fields = childStepElement.getFieldsToSave();
            }

            let step;
            if (this.isCreation) {
                const safeCreateRecord = handleAsyncError(this.createRecord, {
                    title: this.label.Create_Record_Error_Title
                });
                step = await safeCreateRecord(this, fields);
            } else {
                const safeUpdateRecord = handleAsyncError(this.updateRecord, {
                    title: this.label.Update_Record_Error_Title
                });
                step = await safeUpdateRecord(this, fields);
            }

            if (step) {
                showToastSuccess(this, {
                    message: this.label.Step_Saved
                });

                if (childStepElement.upsertChildAttachment) {
                    // Step cannot be rolled back, step can be saved successfully,
                    // although related attachment may still fail on upsert
                    await childStepElement.upsertChildAttachment(step.id);
                }

                this.restoreOriginalValues();

                // Using standard onlightning__showtoast we cannot access toastAttributes because of Locker Service
                this.dispatchEvent(new CustomEvent('refreshdata'));
            }
        }

        this.showSpinner = false;
    }

    childStepElement() {
        // IMPORTANT: Keep naming convention for different deployment steps types components
        const childStepComponentName = 'c-deployment-steps' + this.convertCamelCaseToKebabCase(this.selectedStepType.replace(' ', ''));
        return this.template.querySelector(childStepComponentName);
    }

    convertCamelCaseToKebabCase(string) {
        return string.replace(/([a-z0-9]|(?=[A-Z]))([A-Z])/g, '$1-$2').toLowerCase();
    }

    createRecord(self, fields) {
        fields[NAME_FIELD.fieldApiName] = self.inputStepName;
        fields[TYPE_FIELD.fieldApiName] = self.selectedStepType;
        fields[DEPLOYMENT_FIELD.fieldApiName] = self.currentDeploymentId;
        const recordInput = { apiName: STEP_OBJECT.objectApiName, fields };
        return createRecord(recordInput);
    }

    updateRecord(self, fields) {
        fields[ID_FIELD.fieldApiName] = self.selectedStepId;
        fields[NAME_FIELD.fieldApiName] = self.inputStepName ? self.inputStepName : self.selectedStepName;
        const recordInput = { fields };
        return updateRecord(recordInput);
    }

    @api restoreOriginalValues() {
        // Restore child component original values
        const childStepElement = this.childStepElement();
        if (childStepElement) childStepElement.restoreOriginalValues();

        this.inputStepName = undefined;
        this.dispatchEvent(new CustomEvent('restoreoriginalvalues'));
    }
}