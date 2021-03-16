import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';

import { handleAsyncError } from 'c/copadocoreUtils';

import relatedListResources from '@salesforce/resourceUrl/relatedListResources';
import fetchRelatedListConfig from '@salesforce/apex/RelatedListController.fetchRelatedListConfig';

import NEW from '@salesforce/label/c.NEW';
import Related_List_Error from '@salesforce/label/c.Related_List_Error';
import View_All from '@salesforce/label/c.View_All';

const actions = [
    { label: 'View', name: 'view' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

// Global value that will increase for each component instance
let _numberOfCurrentInstance = 0;

export default class RelatedList extends NavigationMixin(LightningElement) {
    label = {
        NEW,
        Related_List_Error,
        View_All
    };

    // Required
    @api recordId;
    @api relatedList;
    @api fieldset;

    // Optional
    @api relationshipField;
    @api orderBy = 'Id ASC NULLS LAST, CreatedDate';
    @api recordSize = 6;
    @api height = 'auto';

    @api hideHeader;
    @api headerIcon;
    @api hideFooter;
    @api isOuterComponent;

    // Optional, datatable specific
    @api showRowNumberColumn;
    @api hideCheckboxColumn;
    @api resizeColumnDisabled;
    @api enableInfiniteLoading;
    @api hideDefaultColumnsActions

    // Optional, not available for manual input
    @api actions = actions;
    @api implementsDragAndDrop;
    @api customHandleNewEnabled;
    @api customHandleRowActionEnabled;

    showSpinner;

    // Needed to give a different id to each individual instance of this component in the same page,
    // so that we can individually scope css dynamically for each of them
    instance = `instance${_numberOfCurrentInstance}`;

    _iconName;
    _childListName;
    _sobjectLabel;
    _sobjectLabelPlural;
    _accumulatedRecordsRetrieved = 0;
    _numberOfRecordsTitle;
    _isStyleApplied;

    get iconName() {
        return this.headerIcon || this._iconName;
    }

    get title() {
        return `${this._sobjectLabelPlural || ''} ${this._numberOfRecordsTitle || ''}`;
    }

    _baseLightningLayoutClasses = 'slds-m-top_x-small';
    get lightningLayoutClasses() {
        return this.isOuterComponent ? this._baseLightningLayoutClasses : `${this._baseLightningLayoutClasses} slds-box slds-p-around_none`;
    }

    _baseHeaderClasses = 'slds-media slds-media_center slds-has-flexi-truncate';
    get headerClasses() {
        return this.isOuterComponent ? this._baseHeaderClasses : `${this._baseHeaderClasses} slds-p-top_medium slds-p-horizontal_medium`;
    }

    _baseFooterClasses = 'slds-card__footer slds-m-top_none';
    get footerClasses() {
        return this.height !== 'auto' ? this._baseFooterClasses : `${this._baseFooterClasses} no-border-top`;
    }

    // If this.recordSize is received from the parent, we need to parse it from string to number: Number(this.recordSize)
    get numberOfRecords() {
        return Number(this.recordSize);
    }

    connectedCallback() {
        _numberOfCurrentInstance++;
        // Retrieve related list configuration in connectedCallback instead of wired methods
        // since relationshipField is optional and, if it is never assigned, wired method is
        // is never called
        this.showSpinner = true;
        this.getRelatedListConfig();
        this.showSpinner = false;
    }

    renderedCallback() {
        loadStyle(this, relatedListResources + '/relatedList.css');
        this.applyStyle();
    }

    /*Separate first real column header from the left of the table*/
    applyStyle() {
        if (!this._isStyleApplied) {
            let firstColumnIndex = 1;
            if (this.showRowNumberColumn) {
                firstColumnIndex++;
            }
            if (!this.hideCheckboxColumn) {
                firstColumnIndex++;
            }
            const style = document.createElement('style');
            // TODO: add proper width to the same element where padding-left is applied,
            // in order to make resize border visible if column resizing is enabled
            style.innerText = `
                [data-instance="${this.instance}"] thead>tr>th:nth-child(${firstColumnIndex}) {
                    padding-left: var(--lwc-varSpacingXSmall);
                }
            `;
            this.template.querySelector('.related-list').appendChild(style);
            this._isStyleApplied = true;
        }
    }

    async getRelatedListConfig() {
        const safeFetchRelatedListConfig = handleAsyncError(this.fetchRelatedListConfig, {
            title: this.label.Related_List_Error
        });

        const relatedListConfig = await safeFetchRelatedListConfig(this, {
            parentId: this.recordId,
            fromObject: this.relatedList,
            relationshipField: this.relationshipField
        });

        if (relatedListConfig) {
            this._iconName = relatedListConfig.iconName;
            this.childListName = relatedListConfig.childListName;
            this._sobjectLabel = relatedListConfig.sobjectLabel;
            this._sobjectLabelPlural = relatedListConfig.sobjectLabelPlural;
        }
    }

    /**
     * Wrapper function with self (although unused) parameter so it can be used by handlerAsyncError
     */
    fetchRelatedListConfig(self, queryConfig) {
        return fetchRelatedListConfig(queryConfig);
    }

    handleRetrievedRows(event) {
        const numberOfRecordsRetrieved = event.detail.numberOfRecordsRetrieved;
        let numberOfRecordsTitle;

        if (numberOfRecordsRetrieved > this.numberOfRecords) {
            this._accumulatedRecordsRetrieved += this.numberOfRecords;
            numberOfRecordsTitle = `(${this._accumulatedRecordsRetrieved}+)`;
        } else {
            this._accumulatedRecordsRetrieved += numberOfRecordsRetrieved;
            numberOfRecordsTitle = `(${this._accumulatedRecordsRetrieved})`;
        }

        this._numberOfRecordsTitle = numberOfRecordsTitle;

        const retrievedRowsEvent = new CustomEvent('retrievedrows', {
            detail: event.detail
        });
        this.dispatchEvent(retrievedRowsEvent);
    }

    handleCreateRecord() {
        if (this.customHandleNewEnabled) {
            this.dispatchEvent(new CustomEvent('createrecord'));
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.relatedList,
                    actionName: 'new'
                }
            });
        }
    }

    handleRowAction(event) {
        if (this.customHandleRowActionEnabled) {
            const rowActionEvent = new CustomEvent('rowaction', {
                detail: event.detail
            });
            this.dispatchEvent(rowActionEvent);
        } else {
            const actionName = event.detail.action.name;
            const row = event.detail.row;
            this.handleDefaultActions(actionName, row);
        }
    }

    handleDefaultActions(actionName, row) {
        switch (actionName) {
            case 'view':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'view'
                    }
                });
                break;
            case 'edit':
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row.Id,
                        actionName: 'edit'
                    }
                });
                break;
            case 'delete':
                this.handleDeleteRecord(row);
                break;
            default:
        }
    }

    handleDeleteRecord(row) {
        const deletePopup = this.template.querySelector('c-related-list-delete-popup');
        deletePopup.recordId = row.Id;
        deletePopup.sobjectLabel = this._sobjectLabel;
        deletePopup.show();
    }

    handleGoToRelatedList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                relationshipApiName: this.childListName,
                actionName: 'view'
            }
        });
    }

    handleDropRow(event) {
        const dropRowEvent = new CustomEvent('droprow', {
            detail: event.detail
        });
        this.dispatchEvent(dropRowEvent);
    }

    @api handleRefresh() {
        this._accumulatedRecordsRetrieved = 0;
        this.template.querySelector('c-copadocore-dynamic-datatable').handleRefresh();
    }
}