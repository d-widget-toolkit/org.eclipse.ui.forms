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
module org.eclipse.ui.forms.DetailsPart;

import org.eclipse.ui.forms.IFormPart;
import org.eclipse.ui.forms.IPartSelectionListener;
import org.eclipse.ui.forms.IManagedForm;
import org.eclipse.ui.forms.IDetailsPageProvider;
import org.eclipse.ui.forms.IDetailsPage;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.BusyIndicator;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.forms.widgets.ScrolledPageBook;

import java.lang.all;
import java.util.Hashtable;
import java.util.Enumeration;
import java.util.Iterator;
import java.util.Set;

/**
 * This managed form part handles the 'details' portion of the
 * 'master/details' block. It has a page book that manages pages
 * of details registered for the current selection.
 * <p>By default, details part accepts any number of pages.
 * If dynamic page provider is registered, this number may
 * be excessive. To avoid running out of steam (by creating
 * a large number of pages with widgets on each), maximum
 * number of pages can be set to some reasonable value (e.g. 10).
 * When this number is reached, old pages (those created first)
 * will be removed and disposed as new ones are added. If
 * the disposed pages are needed again after that, they
 * will be created again.
 *
 * @since 3.0
 */
public final class DetailsPart : IFormPart, IPartSelectionListener {
    private IManagedForm managedForm;
    private ScrolledPageBook pageBook;
    private IFormPart masterPart;
    private IStructuredSelection currentSelection;
    private Hashtable pages;
    private IDetailsPageProvider pageProvider;
    private int pageLimit=Integer.MAX_VALUE;

    private static class PageBag {
        private static int counter;
        private int ticket;
        private IDetailsPage page;
        private bool fixed;

        public this(IDetailsPage page, bool fixed) {
            this.page= page;
            this.fixed = fixed;
            this.ticket = ++counter;
        }
        public int getTicket() {
            return ticket;
        }
        public IDetailsPage getPage() {
            return page;
        }
        public void dispose() {
            page.dispose();
            page=null;
        }
        public bool isDisposed() {
            return page is null;
        }
        public bool isFixed() {
            return fixed;
        }
        public static int getCurrentTicket() {
            return counter;
        }
    }
/**
 * Creates a details part by wrapping the provided page book.
 * @param mform the parent form
 * @param pageBook the page book to wrap
 */
    public this(IManagedForm mform, ScrolledPageBook pageBook) {
        this.pageBook = pageBook;
        pages = new Hashtable();
        initialize(mform);
    }
/**
 * Creates a new details part in the provided form by creating
 * the page book.
 * @param mform the parent form
 * @param parent the composite to create the page book in
 * @param style the style for the page book
 */
    public this(IManagedForm mform, Composite parent, int style) {
        this(mform, mform.getToolkit().createPageBook(parent, style|SWT.V_SCROLL|SWT.H_SCROLL));
    }
/**
 * Registers the details page to be used for all the objects of
 * the provided object class.
 * @param objectClass an object of type 'java.lang.Class' to be used
 * as a key for the provided page
 * @param page the page to show for objects of the provided object class
 */
    public void registerPage(Object objectClass, IDetailsPage page) {
        registerPage(objectClass, page, true);
    }

    private void registerPage(Object objectClass, IDetailsPage page, bool fixed) {
        pages.put(objectClass, new PageBag(page, fixed));
        page.initialize(managedForm);
    }
/**
 * Sets the dynamic page provider. The dynamic provider can return
 * different pages for objects of the same class based on their state.
 * @param provider the provider to use
 */
    public void setPageProvider(IDetailsPageProvider provider) {
        this.pageProvider = provider;
    }
/**
 * Commits the part by committing the current page.
 * @param onSave <code>true</code> if commit is requested as a result
 * of the 'save' action, <code>false</code> otherwise.
 */
    public void commit(bool onSave) {
        IDetailsPage page = getCurrentPage();
        if (page !is null)
            page.commit(onSave);
    }
/**
 * Returns the current page visible in the part.
 * @return the current page
 */
    public IDetailsPage getCurrentPage() {
        Control control = pageBook.getCurrentPage();
        if (control !is null) {
            Object data = control.getData();
            if (null !is cast(IDetailsPage)data )
                return cast(IDetailsPage) data;
        }
        return null;
    }
    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IFormPart#dispose()
     */
    public void dispose() {
        for (Enumeration enm = pages.elements(); enm.hasMoreElements();) {
            PageBag pageBag = cast(PageBag) enm.nextElement();
            pageBag.dispose();
        }
    }
    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IFormPart#initialize(org.eclipse.ui.forms.IManagedForm)
     */
    public void initialize(IManagedForm form) {
        this.managedForm = form;
    }
/**
 * Tests if the currently visible page is dirty.
 * @return <code>true</code> if the page is dirty, <code>false</code> otherwise.
 */
    public bool isDirty() {
        IDetailsPage page = getCurrentPage();
        if (page !is null)
            return page.isDirty();
        return false;
    }
/**
 * Tests if the currently visible page is stale and needs refreshing.
 * @return <code>true</code> if the page is stale, <code>false</code> otherwise.
 */
    public bool isStale() {
        IDetailsPage page = getCurrentPage();
        if (page !is null)
            return page.isStale();
        return false;
    }

/**
 * Refreshes the current page.
 */
    public void refresh() {
        IDetailsPage page = getCurrentPage();
        if (page !is null)
            page.refresh();
    }
/**
 * Sets the focus to the currently visible page.
 */
    public void setFocus() {
        IDetailsPage page = getCurrentPage();
        if (page !is null)
            page.setFocus();
    }
    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IFormPart#setFormInput(java.lang.Object)
     */
    public bool setFormInput(Object input) {
        return false;
    }
    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.ui.forms.IPartSelectionListener#selectionChanged(org.eclipse.ui.forms.IFormPart,
     *      org.eclipse.jface.viewers.ISelection)
     */
    public void selectionChanged(IFormPart part, ISelection selection) {
        this.masterPart = part;
        if (currentSelection !is null) {
        }
        if (null !is cast(IStructuredSelection)selection )
            currentSelection = cast(IStructuredSelection) selection;
        else
            currentSelection = null;
        update();
    }
    private void update() {
        Object key = null;
        if (currentSelection !is null) {
            for (Iterator iter = currentSelection.iterator(); iter.hasNext();) {
                Object obj = iter.next();
                if (key is null)
                    key = getKey(obj);
                else if (getKey(obj).opEquals(key) is false) {
                    key = null;
                    break;
                }
            }
        }
        showPage(key);
    }
    private Object getKey(Object object) {
        if (pageProvider !is null) {
            Object key = pageProvider.getPageKey(object);
            if (key !is null)
                return key;
        }
        return object.classinfo;
    }
    private void showPage( Object key) {
        checkLimit();
        final IDetailsPage oldPage = getCurrentPage();
        if (key !is null) {
            PageBag pageBag = cast(PageBag)pages.get(key);
            IDetailsPage page = pageBag !is null?pageBag.getPage():null;
            if (page is null) {
                // try to get the page dynamically from the provider
                if (pageProvider !is null) {
                    page = pageProvider.getPage(key);
                    if (page !is null) {
                        registerPage(key, page, false);
                    }
                }
            }
            if (page !is null) {
                BusyIndicator.showWhile(pageBook.getDisplay(), dgRunnable( (IDetailsPage fpage,Object key,IDetailsPage oldPage) {
                    if (!pageBook.hasPage(key)) {
                        Composite parent = pageBook.createPage(key);
                        fpage.createContents(parent);
                        parent.setData(cast(Object)fpage);
                    }
                    //commit the current page
                    if (oldPage !is null && oldPage.isDirty())
                        oldPage.commit(false);
                    //refresh the new page
                    if (fpage.isStale())
                        fpage.refresh();
                    fpage.selectionChanged(masterPart, currentSelection);
                    pageBook.showPage(key);
                }, page, key, oldPage));
                return;
            }
        }
        // If we are switching from an old page to nothing,
        // don't loose data
        if (oldPage !is null && oldPage.isDirty())
            oldPage.commit(false);
        pageBook.showEmptyPage();
    }
    private void checkLimit() {
        if (pages.size() <= getPageLimit()) return;
        // overflow
        int currentTicket = PageBag.getCurrentTicket();
        int cutoffTicket = currentTicket - getPageLimit();
        for (Enumeration enm=pages.keys(); enm.hasMoreElements();) {
            Object key = enm.nextElement();
            PageBag pageBag = cast(PageBag)pages.get(key);
            if (pageBag.getTicket()<=cutoffTicket) {
                // candidate - see if it is active and not fixed
                if (!pageBag.isFixed() && !(cast(Object)pageBag.getPage()).opEquals(cast(Object)getCurrentPage())) {
                    // drop it
                    pageBag.dispose();
                    pages.remove(key);
                    pageBook.removePage(key, false);
                }
            }
        }
    }
    /**
     * Returns the maximum number of pages that should be
     * maintained in this part. When an attempt is made to
     * add more pages, old pages are removed and disposed
     * based on the order of creation (the oldest pages
     * are removed). The exception is made for the
     * page that should otherwise be disposed but is
     * currently active.
     * @return maximum number of pages for this part
     */
    public int getPageLimit() {
        return pageLimit;
    }
    /**
     * Sets the page limit for this part.
     * @see #getPageLimit()
     * @param pageLimit the maximum number of pages that
     * should be maintained in this part.
     */
    public void setPageLimit(int pageLimit) {
        this.pageLimit = pageLimit;
        checkLimit();
    }
}
