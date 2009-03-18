/*******************************************************************************
 * Copyright (c) 2000, 2005 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.ImageSegment;

import org.eclipse.ui.internal.forms.widgets.ObjectSegment;
import org.eclipse.ui.internal.forms.widgets.SelectionData;
import org.eclipse.ui.internal.forms.widgets.FormUtil;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;

import java.lang.all;
import java.util.Hashtable;
import java.util.Set;

/**
 * @version 1.0
 * @author
 */
public class ImageSegment : ObjectSegment {
    public static const String SEL_IMAGE_PREFIX = "isel."; //$NON-NLS-1$

    public Image getImage(Hashtable objectTable) {
        return getImage(getObjectId(), objectTable);
    }

    private Image getImage(String key, Hashtable objectTable) {
        if (key is null)
            return null;
        Object obj = objectTable.get(key);
        if (obj is null)
            return null;
        if ( auto image = cast(Image)obj )
            return image;
        return null;
    }

    private Image getSelectedImage(Hashtable objectTable, SelectionData selData) {
        String key = SEL_IMAGE_PREFIX ~ getObjectId();
        Image image = getImage(key, objectTable);
        if (image is null) {
            image = FormUtil.createAlphaMashImage(selData.display, getImage(objectTable));
            if (image !is null)
                objectTable.put(key, image);
        }
        return image;
    }
/*
    private String getSelectedImageId() {
        if (getObjectId() is null)
            return null;
        return SEL_IMAGE_PREFIX + getObjectId();
    }
*/

    public void paint(GC gc, bool hover, Hashtable resourceTable, bool selected, SelectionData selData, Rectangle repaintRegion) {
        Image image = getImage(resourceTable);
        int iwidth = 0;
        int iheight = 0;
        if (image !is null) {
            Rectangle rect = image.getBounds();
            iwidth = rect.width + (isSelectable()?2:0);
            iheight = rect.height + (isSelectable()?2:0);
        } else
            return;
        Rectangle bounds = getBounds();
        int ix = bounds.x+(isSelectable()?1:0);
        int iy = bounds.y+(isSelectable()?1:0);

        if (selData !is null) {
            int leftOffset = selData.getLeftOffset(bounds.height);
            int rightOffset = selData.getRightOffset(bounds.height);
            bool firstRow = selData.isFirstSelectionRow(bounds.y,
                    bounds.height);
            bool lastRow = selData.isLastSelectionRow(bounds.y,
                    bounds.height);
            bool selectedRow = selData
                    .isSelectedRow(bounds.y, bounds.height);
            if (selectedRow) {
                if ((firstRow && leftOffset > ix) ||
                    (lastRow && rightOffset < ix + iwidth/2)) {
                    drawClipImage(gc, image, ix, iy, repaintRegion);
                }
                else {
                    Color savedBg = gc.getBackground();
                    gc.setBackground(selData.bg);
                    int sx = ix;
                    int sy = iy;
                    if (repaintRegion !is null) {
                        sx -= repaintRegion.x;
                        sy -= repaintRegion.y;
                    }
                    gc.fillRectangle(sx, sy, iwidth, iheight);
                    Image selImage = getSelectedImage(resourceTable, selData);
                    gc.drawImage(selImage, sx, sy);
                    gc.setBackground(savedBg);
                }
            }
            else
                drawClipImage(gc, image, ix, iy, repaintRegion);
        } else
            drawClipImage(gc, image, ix, iy, repaintRegion);
        if (selected) {
            int fx = bounds.x;
            int fy = bounds.y;
            if (repaintRegion !is null) {
                fx -= repaintRegion.x;
                fy -= repaintRegion.y;
            }
            Color fg = gc.getForeground();
            gc.setForeground(gc.getBackground());
            // Clean up to avoid canceling out XOR if it is already
            // selected.
            gc.drawRectangle(bounds.x, bounds.y, bounds.width - 1,
                    bounds.height - 1);
            gc.setForeground(fg);
            gc.drawFocus(fx, fy, bounds.width, bounds.height);
        }
    }
    private void drawClipImage(GC gc, Image image, int ix, int iy, Rectangle repaintRegion) {
        if (repaintRegion !is null) {
            ix -= repaintRegion.x;
            iy -= repaintRegion.y;
        }
        gc.drawImage(image, ix, iy);
    }

    protected Point getObjectSize(Hashtable resourceTable, int wHint) {
        Image image = getImage(resourceTable);
        if (image is null)
            return new Point(0, 0);
        Rectangle ibounds = image.getBounds();
        return new Point(ibounds.width, ibounds.height);
    }
}
