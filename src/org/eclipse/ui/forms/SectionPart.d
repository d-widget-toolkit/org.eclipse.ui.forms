/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module org.eclipse.ui.forms.SectionPart;

import org.eclipse.ui.forms.AbstractFormPart;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.ui.forms.events.ExpansionAdapter;
import org.eclipse.ui.forms.events.ExpansionEvent;
import org.eclipse.ui.forms.widgets.FormToolkit;
import org.eclipse.ui.forms.widgets.Section;

import java.lang.all;
import java.util.Set;

/**
 * Section part implements IFormPart interface based on the Section widget. It
 * can either wrap the widget or create one itself.
 * <p>
 * Subclasses should extend <code>SectionPart</code> and implement life cycle
 * methods like <code>refresh</code>, <code>commit</code>,
 * <code>setFocus</code> etc. Note that most of these methods are not empty -
 * calling <code>super</code> is required.
 *
 * @see Section
 * @since 3.0
 */
public class SectionPart : AbstractFormPart {
    private Section section;

    /**
     * Creates a new section part based on the provided section.
     *
     * @param section
     *            the section to use
     */
    public this(Section section) {
        this.section = section;
        hookListeners();
    }

    /**
     * Creates a new section part inside the provided parent and using the
     * provided toolkit. The section part will create the section widget.
     *
     * @param parent
     *            the parent
     * @param toolkit
     *            the toolkit to use
     * @param style
     *            the section widget style
     */
    public this(Composite parent, FormToolkit toolkit, int style) {
        this(toolkit.createSection(parent, style));
    }

    /**
     * Adds listeners to the underlying widget.
     */
    protected void hookListeners() {
        if ((section.getExpansionStyle() & Section.TWISTIE) !is 0
                || (section.getExpansionStyle() & Section.TREE_NODE) !is 0) {
            section.addExpansionListener(new class ExpansionAdapter {
                public void expansionStateChanging(ExpansionEvent e) {
                    this.outer.expansionStateChanging(e.getState());
                }

                public void expansionStateChanged(ExpansionEvent e) {
                    this.outer.expansionStateChanged(e.getState());
                }
            });
        }
    }

    /**
     * Returns the section widget used in this part.
     *
     * @return the section widget
     */
    public Section getSection() {
        return section;
    }

    /**
     * The section is about to expand or collapse.
     *
     * @param expanding
     *            <code>true</code> for expansion, <code>false</code> for
     *            collapse.
     */
    protected void expansionStateChanging(bool expanding) {
    }

    /**
     * The section has expanded or collapsed.
     *
     * @param expanded
     *            <code>true</code> for expansion, <code>false</code> for
     *            collapse.
     */
    protected void expansionStateChanged(bool expanded) {
        getManagedForm().getForm().reflow(false);
    }

    /* (non-Javadoc)
     * @see org.eclipse.ui.forms.AbstractFormPart#setFocus()
     */
    public void setFocus() {
        Control client = section.getClient();
        if (client !is null)
            client.setFocus();
    }
}
