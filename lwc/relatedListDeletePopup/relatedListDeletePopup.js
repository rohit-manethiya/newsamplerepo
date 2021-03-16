import { LightningElement, api } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';

import { handleAsyncError } from 'c/copadocoreUtils';
import { showToastSuccess } from 'c/copadocoreToastNotification';

import Cancel from '@salesforce/label/c.Cancel';
import DELETE from '@salesforce/label/c.DELETE';
import Delete_Confirmation from '@salesforce/label/c.Delete_Confirmation';
import Error_Deleting_Record from '@salesforce/label/c.Error_Deleting_Record';
import Record_Deleted_Successfully from '@salesforce/label/c.Record_Deleted_Successfully';

export default class RelatedListDeletePopup extends LightningElement {
    label = {
        Cancel,
        DELETE,
        Delete_Confirmation,
        Error_Deleting_Record,
        Record_Deleted_Successfully
    };

    @api recordId;
    @api sobjectLabel;

    get body() {
        return `${this.label.Delete_Confirmation} ${this.sobjectLabel ? this.sobjectLabel.toLowerCase() : ''}?`;
    }

    get title() {
        return `${this.label.DELETE} ${this.sobjectLabel}`;
    }

    @api show() {
        this.template.querySelector('c-copadocore-modal').show();
    }

    @api hide() {
        this.template.querySelector('c-copadocore-modal').hide();
    }

    handleCancel() {
        this.hide();
    }

    async handleDelete() {
        this.hide();

        const safeDeleteRecord = handleAsyncError(this.deleteRecord, {
            title: this.label.Error_Deleting_Record
        });
        await safeDeleteRecord(this, this.recordId);

        showToastSuccess(this, {
            title: `${this.sobjectLabel} ${this.label.Record_Deleted_Successfully}.`
        });
        this.dispatchEvent(new CustomEvent('recorddeleted'));
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    deleteRecord(self, recordId) {
        return deleteRecord(recordId);
    }
}