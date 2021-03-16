import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';

import { showToastError } from 'c/copadocoreToastNotification';
import { autoFormValidation, handleAsyncError } from 'c/copadocoreUtils';

import getLastAttachmentBodyAsString from '@salesforce/apex/DeploymentStepsUtils.getLastAttachmentBodyAsString';
import upsertAttachment from '@salesforce/apex/DeploymentStepsUtils.upsertAttachment';

import Apex_Script from '@salesforce/label/c.Apex_Script';
import Apex_Script_Placeholder from '@salesforce/label/c.Apex_Script_Placeholder';
import Error_Upserting_Attachment from '@salesforce/label/c.Error_Upserting_Attachment';

export default class DeploymentStepsApex extends LightningElement {
    label = {
        Apex_Script,
        Apex_Script_Placeholder,
        Error_Upserting_Attachment
    };

    @api stepId;

    apexScriptValue;

    // This variables are used to reset edited step information to the original value
    _originalApexScriptValue;

    // Variable to store retrieved data from apex so it can be refreshed when it changes
    _wiredAttachmentBodyValue;

    // If stepId changes, no matter if it is actually another valid step Id or not,
    // the wiredAttachmentBody is called again, since it is just an apex method parameter
    @wire(getLastAttachmentBodyAsString, { name: 'Apex', parentId: '$stepId' })
    wiredAttachmentBody(value) {
        const { data, error } = (this._wiredAttachmentBodyValue = value);
        if (data) {
            this._originalApexScriptValue = this.apexScriptValue = data;
        } else if (error) {
            showToastError(this, {
                message: error.body ? error.body.message : error.message
            });
            console.error(error);
            this._originalApexScriptValue = this.apexScriptValue = undefined;
        }
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
    }

    @api
    getAutoFormValidation() {
        return autoFormValidation(this.template, this);
    }

    @api
    async upsertChildAttachment(parentId) {
        const safeUpsertAttachment = handleAsyncError(this.upsertAttachment, {
            title: this.label.Error_Upserting_Attachment
        });

        const result = await safeUpsertAttachment(this, {
            name: 'Apex',
            parentId: parentId,
            body: this.apexScriptValue
        });

        if (result) {
            refreshApex(this._wiredAttachmentBodyValue);
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    upsertAttachment(self, fields) {
        return upsertAttachment(fields);
    }

    @api
    restoreOriginalValues() {
        this.apexScriptValue = this._originalApexScriptValue;
    }
}