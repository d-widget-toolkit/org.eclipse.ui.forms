/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.ui.forms.widgets.TableWrapData;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;

import java.lang.all;
import java.util.Set;

/**
 * Layout data used in conjunction with <code>HTMLTableLayout</code>.
 * Children in a composite that uses this layout should call <samp>setLayoutData
 * </samp> and pass an instance of this class to control physical placement in
 * the parent.
 *
 * @see TableWrapLayout
 * @since 3.0
 */
public final class TableWrapData {
    /**
     * The control will be left-justified.
     */
    public static const int LEFT = 1 << 1;

    /**
     * The control will be centered horizontally.
     */
    public static const int CENTER = 1 << 2;

    /**
     * The control will be right-justified.
     */
    public static const int RIGHT = 1 << 3;

    /**
     * The control will be aligned with the top of the cell.
     */
    public static const int TOP = 1 << 4;

    /**
     * The control will be centered vertically.
     */
    public static const int MIDDLE = 1 << 5;

    /**
     * The control will be aligned with the bottom of the cell.
     */
    public static const int BOTTOM = 1 << 6;

    /**
     * The control will have the same width as the column it occupies.
     */
    public static const int FILL = 1 << 7;

    /**
     * In addition to filling width or height, the control will take part in
     * allocation of any excess space. Note that this constant can only be
     * passed to the constructor (cannot be directly assigned to
     * <code>align</code> variable).
     */
    public static const int FILL_GRAB = 1 << 8;

    /**
     * Number of columns to span (default is 1).
     */
    public int colspan = 1;

    /**
     * Number of rows to span (default is 1).
     */
    public int rowspan = 1;

    /**
     * Horizontal alignment (LEFT, CENTER, RIGHT or FILL; default is LEFT).
     */
    public int align_ = LEFT;

    /**
     * Vertical alignment (TOP, MIDDLE, BOTTOM or FILL; default is TOP).
     */
    public int valign = TOP;

    /**
     * Horizontal indent (default is 0).
     */
    public int indent = 0;

    /**
     * Maximum width of the control (default is SWT.DEFAULT).
     */
    public int maxWidth = SWT.DEFAULT;

    /**
     * Maximum height of the control (default is SWT.DEFAULT).
     */
    public int maxHeight = SWT.DEFAULT;

    /**
     * Height hint of the control (default is SWT.DEFAULT).
     */
    public int heightHint = SWT.DEFAULT;

    /**
     * If <code>true</code>, take part in excess horizontal space
     * distribution. (default is <code>false</code>).
     */
    public bool grabHorizontal;

    /**
     * If <code>true</code>, will grab any excess vertical space (default is
     * <code>false</code>). Note that since TableWrapLayout works top-down
     * and does not grows to fill the parent, this only applies to local excess
     * space created by fixed-height children that span multiple rows.
     */
    public bool grabVertical;

    int childIndex;

    bool isItemData = true;

    int compWidth;

    Point compSize;

    /**
     * The default constructor.
     */
    public this() {
    }

    /**
     * The convenience constructor - allows passing the horizontal alignment
     * style.
     *
     * @param align
     *            horizontal alignment (LEFT, CENTER, RIGHT, FILL or FILL_GRAB).
     */
    public this(int align_) {
        this(align_, TOP, 1, 1);
    }

    /**
     * The convenience constructor - allows passing the alignment styles.
     *
     * @param align
     *            horizontal alignment (LEFT, CENTER, RIGHT, FILL or FILL_GRAB).
     * @param valign
     *            vertical alignment (TOP, MIDDLE, BOTTOM, FILL or FILL_GRAB).
     */
    public this(int align_, int valign) {
        this(align_, valign, 1, 1);
    }

    /**
     * The convenience constructor - allows passing the alignment styles, column
     * and row spans.
     *
     * @param align
     *            horizontal alignment (LEFT, CENTER, RIGHT, FILL or FILL_GRAB).
     * @param valign
     *            vertical alignment (TOP, MIDDLE, BOTTOM, FILL or FILL_GRAB)
     * @param rowspan
     *            row span (1 or more)
     * @param colspan
     *            column span (1 or more)
     */
    public this(int align_, int valign, int rowspan, int colspan) {
        if (align_ !is LEFT && align_ !is CENTER && align_ !is RIGHT && align_ !is FILL
                && align_ !is FILL_GRAB)
            SWT.error(SWT.ERROR_INVALID_ARGUMENT, null, "align"); //$NON-NLS-1$
        if (valign !is TOP && valign !is MIDDLE && valign !is BOTTOM
                && valign !is FILL && valign !is FILL_GRAB)
            SWT.error(SWT.ERROR_INVALID_ARGUMENT, null, "valign"); //$NON-NLS-1$
        if (rowspan < 1)
            SWT.error(SWT.ERROR_INVALID_ARGUMENT, null, "rowspan"); //$NON-NLS-1$
        if (colspan < 1)
            SWT.error(SWT.ERROR_INVALID_ARGUMENT, null, "colspan"); //$NON-NLS-1$
        if (align_ is FILL_GRAB) {
            this.align_ = FILL;
            grabHorizontal = true;
        } else
            this.align_ = align_;
        if (valign is FILL_GRAB) {
            this.valign = FILL;
            grabVertical = true;
        } else
            this.valign = valign;
        this.rowspan = rowspan;
        this.colspan = colspan;
    }
}
