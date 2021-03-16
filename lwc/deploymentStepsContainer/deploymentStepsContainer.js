import { LightningElement, api } from 'lwc';

import { handleAsyncError } from 'c/copadocoreUtils';

import NAME_FIELD from '@salesforce/schema/Step__c.Name';
import TYPE_FIELD from '@salesforce/schema/Step__c.Type__c';
import ORDER_FIELD from '@salesforce/schema/Step__c.Order__c';

import updateRecords from '@salesforce/apex/DeploymentStepsUtils.updateRecords';

import No_Steps_Yet from '@salesforce/label/c.No_Steps_Yet';
import Add_New_Step from '@salesforce/label/c.Add_New_Step';
import Error_Reordering_Steps from '@salesforce/label/c.Error_Reordering_Steps';

const actions = [
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

export default class DeploymentStepsContainer extends LightningElement {
    label = {
        No_Steps_Yet,
        Add_New_Step,
        Error_Reordering_Steps
    };

    @api recordId;

    actions = actions;

    showSpinner;

    selectedStepId;
    selectedStepName;
    selectedStepType;

    // Variable to store event received from row action when deleting a record
    // to properly reorder the steps afterwards
    _auxEvent;

    // Using slds display classes instead of conditional rendering since
    // we do need element rendered to access them even when they do not appear
    hasRecords = true;
    get displayIllustrationClass() {
        return this.hasRecords ? 'slds-hide' : 'slds-show';
    }

    get displayTableClass() {
        return this.hasRecords ? 'slds-show' : 'slds-hide';
    }

    handleCreateStep() {
        this.showStepsModal();
    }

    showStepsModal() {
        const stepsModal = this.template.querySelector('c-deployment-steps-modal');
        stepsModal.show();
    }

    handleRetrievedRows(event) {
        const numberOfRecordsRetrieved = event.detail.numberOfRecordsRetrieved;
        this.hasRecords = numberOfRecordsRetrieved > 0 ? true : false;
    }

    handleDropRow(event) {
        this.reorderSteps(event);
    }

    handleRowAction(event) {
        const action = event.detail.action;
        /* eslint-disable default-case*/
        /* eslint-disable no-case-declarations*/
        switch (action.name) {
            case 'edit':
                this.handleEditRow(event);
                break;
            case 'delete':
                this.handleDeleteRow(event);
                break;
        }
    }

    handleEditRow(event) {
        const row = event.detail.row;
        this.selectedStepId = row.Id;
        this.selectedStepName = row[NAME_FIELD.fieldApiName];
        this.selectedStepType = row[TYPE_FIELD.fieldApiName];
        this.showStepsModal();
    }

    handleDeleteRow(event) {
        const row = event.detail.row;

        // Remove the deleted row from the whole set of the rows in the table
        const tableRows = event.detail.tableRows;
        const deletedRowIndex = tableRows.findIndex((tableRow) => tableRow.Id === row.Id);
        tableRows.splice(deletedRowIndex, 1);

        this._auxEvent = event;

        const deletePopup = this.template.querySelector('c-related-list-delete-popup');
        deletePopup.recordId = row.Id;
        deletePopup.sobjectLabel = 'Step';
        deletePopup.show();

        // deletePopup dispatches onrecorddeleted
    }

    handleRecordDeleted() {
        this.reorderSteps();
    }

    async reorderSteps(event) {
        this.showSpinner = true;
        const safeReorderSteps = handleAsyncError(this.updateRecords, {
            title: this.label.Error_Reordering_Steps
        });

        const dataEvent = event ? event : this._auxEvent;
        const tableRows = dataEvent.detail.tableRows;
        const orderedStepsData = [];
        for (let i = 0, j = tableRows.length; i < j; ) {
            const row = tableRows[i];
            row[ORDER_FIELD.fieldApiName] = ++i;
            orderedStepsData.push(row);
        }
        const result = await safeReorderSteps(this, {
            records: orderedStepsData
        });

        // If it is null (because apex method returns void) or any other value,
        // it means that reorderSteps is successful
        if (result !== undefined) {
            this.refreshDatatable();
        }

        this.showSpinner = false;
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    updateRecords(self, data) {
        return updateRecords(data);
    }

    refreshDatatable() {
        this.template.querySelector('c-related-list').handleRefresh();
    }

    handleRefreshData() {
        this.refreshDatatable();
    }

    handleRestoreOriginalValues() {
        this.selectedStepId = undefined;
        this.selectedStepName = undefined;
        this.selectedStepType = undefined;
    }
}