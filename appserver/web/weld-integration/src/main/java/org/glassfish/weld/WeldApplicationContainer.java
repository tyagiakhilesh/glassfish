/*
 * Copyright (c) 2009, 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v. 2.0, which is available at
 * http://www.eclipse.org/legal/epl-2.0.
 *
 * This Source Code may also be made available under the following Secondary
 * Licenses when the conditions for such availability set forth in the
 * Eclipse Public License v. 2.0 are satisfied: GNU General Public License,
 * version 2 with the GNU Classpath Exception, which is available at
 * https://www.gnu.org/software/classpath/license.html.
 *
 * SPDX-License-Identifier: EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0
 */

package org.glassfish.weld;

import org.glassfish.api.deployment.ApplicationContainer;
import org.glassfish.api.deployment.ApplicationContext;

public class WeldApplicationContainer implements ApplicationContainer {

    public WeldApplicationContainer() {
    }

    public Object getDescriptor() {
        return null;
    }
   
    public boolean start(ApplicationContext startupContxt) {

        return true;
    }

    public boolean stop(ApplicationContext stopContext) {

        return true;
    }

    public boolean suspend() {
        return false;
    }

    public boolean resume() {
        return false;
    }

    public ClassLoader getClassLoader() {
        return null;
    }
}

