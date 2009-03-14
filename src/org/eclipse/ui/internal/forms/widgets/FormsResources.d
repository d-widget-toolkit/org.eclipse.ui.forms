/*******************************************************************************
 * Copyright (c) 2003, 2005 IBM Corporation and others.
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
module org.eclipse.ui.internal.forms.widgets.FormsResources;

import java.lang.all;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Cursor;
import org.eclipse.swt.widgets.Display;

/**
 * Utility methods to access shared form-specific resources.
 * <p>
 * All methods declared on this class are static. This
 * class cannot be instantiated.
 * </p>
 * <p>
 * </p>
 */
public class FormsResources {
    private static Cursor busyCursor;
    private static Cursor handCursor;
    private static Cursor textCursor;

    public static Cursor getBusyCursor() {
        if (busyCursor is null)
            busyCursor = new Cursor(Display.getCurrent(), SWT.CURSOR_WAIT);
        return busyCursor;
    }
    public static Cursor getHandCursor() {
        if (handCursor is null)
            handCursor = new Cursor(Display.getCurrent(), SWT.CURSOR_HAND);
        return handCursor;
    }
    public static Cursor getTextCursor() {
        if (textCursor is null)
            textCursor = new Cursor(Display.getCurrent(), SWT.CURSOR_IBEAM);
        return textCursor;
    }

    public static int getProgressDelay(int index) {
        /*
        if (progressDelays is null)
            return 0;
        return progressDelays[index];
        */
        return 100;
    }

    public static void shutdown() {
        if (busyCursor !is null)
            busyCursor.dispose();
        if (handCursor !is null)
            handCursor.dispose();
        if (textCursor !is null)
            textCursor.dispose();
        busyCursor=null;
        handCursor=null;
        textCursor=null;
    }
}
