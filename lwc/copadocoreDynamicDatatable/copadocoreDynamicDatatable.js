/* eslint-disable guard-for-in */
import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import { registerListener, unregisterAllListeners } from 'c/copadoCorePubsub';
import { handleAsyncError } from 'c/copadocoreUtils';

import fetchColumnsConfig from '@salesforce/apex/DynamicDatatableController.fetchColumnsConfig';
import fetchData from '@salesforce/apex/DynamicDatatableController.fetchData';

import Fetch_Columns_Config_Error from '@salesforce/label/c.Fetch_Columns_Config_Error';
import Fetch_Data_Error from '@salesforce/label/c.Fetch_Data_Error';

/*eslint no-extend-native: ["error", { "exceptions": ["Array"] }]*/
Array.prototype.move = function (from, to) {
    this.splice(to, 0, this.splice(from, 1)[0]);
    return this;
};

const actions = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

export default class CopadocoreDynamicDatatable extends LightningElement {
    @wire(CurrentPageReference) pageRef;

    label = {
        Fetch_Columns_Config_Error,
        Fetch_Data_Error
    };

    // Required
    @api recordId;
    @api relatedList;
    @api fieldset;

    // Optional
    @api lookUpObjectApi;
    @api orderBy = 'Id ASC NULLS LAST, CreatedDate';
    @api recordSize = 6;
    @api heightStyle = 'auto';

    // Optional, datatable specific
    @api showRowNumberColumn;
    @api hideCheckboxColumn;
    @api resizeColumnDisabled;
    @api enableInfiniteLoading;

    @api hideDefaultColumnsActions;

    // Optional, not available for manual input
    @api actions = actions;
    @api implementsDragAndDrop;

    columns = [];
    data = [];

    showSpinner;

    _recordsOffset = 0;
    // Assigned the first time that "loadMoreData" is called
    _table;

    /**
     * Deprecated: cannot be removed due to managed package
     */
    @api height = '750';
    @api showFilter;
    @api showSearch;

    get containerStyle() {
        return `height: ${this.heightStyle};`;
    }

    // If this.recordSize is received from the parent, we need to parse it from string to number: Number(this.recordSize)
    get numberOfRecords() {
        return Number(this.recordSize);
    }

    connectedCallback() {
        registerListener('dropRowEvent', this.switchRowsAfterDrag, this);
        // Retrieve table information in connectedCallback instead of wired methods
        // to be able to set properly the showSpinner value and because we also need
        // to retrieve data imperatively for "onloadmore" event
        this.getTableInformation();
    }

    async getTableInformation() {
        this.showSpinner = true;
        await this.getColumnsConfig();
        await this.getRowsData();
        this.showSpinner = false;
    }

    async getColumnsConfig() {
        const safeFetchColumnsConfig = handleAsyncError(this.fetchColumnsConfig, {
            title: this.label.Fetch_Columns_Config_Error
        });

        const columnsConfig = await safeFetchColumnsConfig(this, {
            objectApiName: this.relatedList,
            fieldSetName: this.fieldset,
            hideDefaultColumnsActions: this.hideDefaultColumnsActions
        });

        if (columnsConfig && columnsConfig.length > 0) {
            this.columns = [...columnsConfig];
            this.setActionsColumn();
            this.setDragAndDropColumn();
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    fetchColumnsConfig(self, columnsConfig) {
        return fetchColumnsConfig(columnsConfig);
    }

    setActionsColumn() {
        if (this.actions && this.actions.length > 0) {
            // We can push to the array because in connectedCallback hook
            // it has not been used by the template yet
            this.columns.push({
                type: 'action',
                fixedWidth: 62,
                typeAttributes: { rowActions: this.actions }
            });
        }
    }

    setDragAndDropColumn() {
        if (this.implementsDragAndDrop) {
            // We can push to the array because in connectedCallback hook
            // it has not been used by the template yet
            this.columns.push({
                hideDefaultActions: true,
                fixedWidth: 62,
                cellAttributes: { iconName: 'utility:drag_and_drop', iconAlternativeText: 'Drag and Drop' }
            });
        }
    }

    async getRowsData() {
        // Reset in case we are refreshing the data
        this._recordsOffset = 0;

        const safeFetchData = handleAsyncError(this.fetchData, {
            title: this.label.Fetch_Data_Error
        });

        const rows = await safeFetchData(this, this.getQueryConfiguration());

        if (rows) {
            this.processData(rows);
            this.data = rows;
            this._recordsOffset += this.numberOfRecords;
        }

        if (this._table) {
            this._table.enableInfiniteLoading = true;
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    fetchData(self, queryConfig) {
        return fetchData(queryConfig);
    }

    getQueryConfiguration() {
        return {
            queryConfig: {
                selectFieldSet: this.fieldset,
                fromObject: this.relatedList,
                relationshipField: this.lookUpObjectApi,
                parentId: this.recordId,
                orderBy: this.orderBy,
                recordsLimit: this.numberOfRecords + 1,
                recordsOffset: this._recordsOffset
            }
        };
    }

    processData(rows) {
        this.generateLinks(rows);

        const retrievedRowsEvent = new CustomEvent('retrievedrows', {
            detail: {
                numberOfRecordsRetrieved: rows.length
            }
        });
        this.dispatchEvent(retrievedRowsEvent);

        if (rows.length > this.numberOfRecords) {
            rows.pop();
        }

        return rows;
    }

    generateLinks(records) {
        records.forEach((record) => {
            record.LinkName = '/' + record.Id;
            for (const propertyName in record) {
                const propertyValue = record[propertyName];
                if (typeof propertyValue === 'object') {
                    const newValue = propertyValue.Id ? '/' + propertyValue.Id : null;
                    this.flattenStructure(record, propertyName + '.', propertyValue);
                    if (newValue !== null) {
                        record[propertyName + '.LinkName'] = newValue;
                    }
                }
            }
        });
    }

    flattenStructure(topObject, prefix, toBeFlattened) {
        for (const propertyName in toBeFlattened) {
            const propertyValue = toBeFlattened[propertyName];
            if (typeof propertyValue === 'object') {
                this.flattenStructure(topObject, prefix + propertyName + '.', propertyValue);
            } else {
                topObject[prefix + propertyName] = propertyValue;
            }
        }
    }

    async loadMoreData(event) {
        // event.target is null after await so we save it in a variable
        this._table = event.target;
        this._table.isLoading = true;

        const safeFetchData = handleAsyncError(this.fetchData, {
            title: this.label.Fetch_Data_Error
        });

        const rows = await safeFetchData(this, this.getQueryConfiguration());

        if (rows && rows.length > 0) {
            this.processData(rows);
            this.data = [...this.data, ...rows];
            this._recordsOffset += this.numberOfRecords;
        } else {
            this._table.enableInfiniteLoading = false;
        }

        this._table.isLoading = false;
    }

    handleRowAction(event) {
        // Deep cloned to avoid sending a reference
        event.detail.tableRows = JSON.parse(JSON.stringify(this.data));
        const rowActionEvent = new CustomEvent('rowaction', {
            detail: event.detail
        });
        this.dispatchEvent(rowActionEvent);
    }

    switchRowsAfterDrag(detail) {
        const draggingBeginsAt = detail.draggingBeginsAt;
        const draggingEndsAt = detail.draggingEndsAt;

        if (draggingBeginsAt === draggingEndsAt) {
            return;
        }

        this.data = this.data.move(draggingBeginsAt, draggingEndsAt);

        const dropRowEvent = new CustomEvent('droprow', {
            // Deep cloned to avoid sending a reference
            detail: { tableRows: JSON.parse(JSON.stringify(this.data)) }
        });
        this.dispatchEvent(dropRowEvent);
    }

    @api handleRefresh() {
        this.getRowsData();
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }
}