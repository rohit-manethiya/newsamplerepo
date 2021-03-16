import { api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import LightningDatatable from 'lightning/datatable';

import { fireEvent } from 'c/copadoCorePubsub';

export default class CopadocoreDatatableExtended extends LightningDatatable {
    @wire(CurrentPageReference) pageRef;

    _tableRows;
    _dragAndDropCells;

    _draggingCell;
    _draggingRow;
    _draggingBeginsAt;
    _draggingEndsAt;

    /**
     * Deprecated: can not be removed due to managed package
     */
    @api draggable;

    get hasDraggingStarted() {
        return this._draggingCell ? true : false;
    }

    // Handler functions bound to this
    _boundHandledMouseDown = this.handleMouseDown.bind(this);
    _boundHandledMouseMove = this.handleMouseMove.bind(this);
    _boundHandledMouseUp = this.handleMouseUp.bind(this);
    _boundHandleMouseLeaveTbody = this.handleMouseLeaveTbody.bind(this);

    constructor() {
        super();
        this.template.addEventListener('mousemove', this._boundHandledMouseMove);
        this.template.addEventListener('mouseup', this._boundHandledMouseUp);
    }

    renderedCallback() {
        super.renderedCallback();
        this.setUpDragAndDrop();
    }

    setUpDragAndDrop() {
        const tbody = this.template.querySelector('tbody');
        tbody.addEventListener('mouseleave', this._boundHandleMouseLeaveTbody);

        const tableRowsNodes = tbody.querySelectorAll('tr');
        this._tableRows = Array.from(tableRowsNodes);
        this._dragAndDropCells = tbody.querySelectorAll('tr>td:last-of-type');

        this.setDraggableCells();
    }

    setDraggableCells() {
        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grab';
            cell.addEventListener('mousedown', this._boundHandledMouseDown);
        });
    }

    handleMouseDown(event) {
        // To cancel default behavior: selection
        event.preventDefault();

        this._draggingCell = event.currentTarget;
        this._draggingRow = this._draggingCell.parentNode;
        this._draggingBeginsAt = this._draggingEndsAt = this._tableRows.indexOf(this._draggingRow);

        this.setStartDraggingStyles(event);
    }

    setStartDraggingStyles() {
        this._draggingRow.classList.add('slds-theme_shade', 'slds-theme_alert-texture');

        this._tableRows.forEach((row) => {
            row.style.cursor = 'grabbing';
        });
        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grabbing';
        });
    }

    handleMouseMove(event) {
        if (this.hasDraggingStarted) {
            const elementPassingThrough = event.target.parentNode;
            if (this._tableRows.includes(elementPassingThrough)) {
                const elementPassingThroughIndex = this._tableRows.indexOf(elementPassingThrough);
                this._draggingEndsAt = elementPassingThroughIndex;
            }
        }
    }

    handleMouseUp() {
        if (this.hasDraggingStarted) {
            const detail = {
                draggingBeginsAt: this._draggingBeginsAt,
                draggingEndsAt: this._draggingEndsAt
            };
            // Can not use this.dispatchEvent due to an issue with LWC
            // extending other components aside from LightningElement
            fireEvent(this.pageRef, 'dropRowEvent', detail);
            this.clearDragAndDropInProgress();
        }
    }

    clearDragAndDropInProgress() {
        this._draggingRow.classList.remove('slds-theme_shade', 'slds-theme_alert-texture');

        this._tableRows.forEach((row) => {
            row.style.cursor = 'default';
        });
        this._dragAndDropCells.forEach((cell) => {
            cell.style.cursor = 'grab';
        });

        this._draggingCell = undefined;
        this._draggingRow = undefined;
        this._draggingBeginsAt = undefined;
        this._draggingEndsAt = undefined;
    }

    handleMouseLeaveTbody() {
        if (this.hasDraggingStarted) {
            this.clearDragAndDropInProgress();
        }
    }
}