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
module org.eclipse.ui.internal.forms.widgets.PixelConverter;

import java.lang.all;

import org.eclipse.swt.graphics.FontMetrics;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.widgets.Control;

public class PixelConverter {
    /**
     * Number of horizontal dialog units per character, value <code>4</code>.
     */
    private static const int HORIZONTAL_DIALOG_UNIT_PER_CHAR = 4;

    private FontMetrics fFontMetrics;

    public this(Control control) {
        GC gc = new GC(control);
        gc.setFont(control.getFont());
        fFontMetrics = gc.getFontMetrics();
        gc.dispose();
    }

    public int convertHorizontalDLUsToPixels(int dlus) {
        // round to the nearest pixel
        return (fFontMetrics.getAverageCharWidth() * dlus + HORIZONTAL_DIALOG_UNIT_PER_CHAR / 2)
                / HORIZONTAL_DIALOG_UNIT_PER_CHAR;
    }
}
