/**
 * The contents of this file are subject to the license and copyright
 * detailed in the LICENSE and NOTICE files at the root of the source
 * tree and available online at
 *
 * http://www.dspace.org/license/
 */
package org.dspace.app.xmlui.aspect.viewArtifacts;

import org.apache.cocoon.caching.CacheableProcessingComponent;
import org.apache.cocoon.environment.ObjectModelHelper;
import org.apache.cocoon.environment.Request;
import org.apache.cocoon.util.HashUtil;
import org.apache.excalibur.source.SourceValidity;
import org.apache.excalibur.source.impl.validity.NOPValidity;
import org.dspace.app.util.Util;
import org.dspace.app.xmlui.cocoon.AbstractDSpaceTransformer;
import org.dspace.app.xmlui.utils.HandleUtil;
import org.dspace.app.xmlui.utils.UIException;
import org.dspace.app.xmlui.wing.WingException;
import org.dspace.app.xmlui.wing.element.Options;
import org.dspace.app.xmlui.wing.element.PageMeta;
import org.dspace.authorize.AuthorizeException;
import org.dspace.content.Collection;
import org.dspace.content.Community;
import org.dspace.content.DSpaceObject;
import org.dspace.content.Item;
import org.dspace.services.factory.DSpaceServicesFactory;
import org.dspace.core.I18nUtil;
import org.xml.sax.SAXException;

import java.io.IOException;
import java.io.Serializable;
import java.util.Locale;
import java.sql.SQLException;

/**
 * This transform applies the basic navigational links that should be available
 * on all pages generated by DSpace.
 *
 * @author Scott Phillips
 * @author Kevin Van de Velde (kevin at atmire dot com)
 * @author Mark Diggory (markd at atmire dot com)
 * @author Ben Bosman (ben at atmire dot com)
 */
public class Navigation extends AbstractDSpaceTransformer implements CacheableProcessingComponent {

    /**
     * Generate the unique caching key.
     * This key must be unique inside the space of this component.
     */
    public Serializable getKey() {
        try {
            Request request = ObjectModelHelper.getRequest(objectModel);
            String key = request.getScheme() + request.getServerName() + request.getServerPort() + request.getSitemapURI() + request.getQueryString();

            DSpaceObject dso = HandleUtil.obtainHandle(objectModel);
            if (dso != null)
            {
                key += "-" + dso.getHandle();
            }

            if (context.getCurrentLocale() != null) {
                key += "-" + context.getCurrentLocale().toString();
            }

            return HashUtil.hash(key);
        }
        catch (SQLException sqle)
        {
            // Ignore all errors and just return that the component is not cachable.
            return "0";
        }
    }

    /**
     * Generate the cache validity object.
     *
     * The cache is always valid.
     */
    public SourceValidity getValidity() {
        return NOPValidity.SHARED_INSTANCE;
    }

        public void addOptions(Options options) throws SAXException, WingException,
            UIException, SQLException, IOException, AuthorizeException
    {
        /* Create skeleton menu structure to ensure consistent order between aspects,
         * even if they are never used
         */
        options.addList("browse");
        options.addList("account");
        options.addList("context");
        options.addList("administrative");
        options.addList("discovery");
    }

    /**
     * Ensure that the context path is added to the page meta.
     */
    public void addPageMeta(PageMeta pageMeta) throws SAXException,
            WingException, UIException, SQLException, IOException,
            AuthorizeException
    {
        // FIXME: I don't think these should be set here, but they're needed and I'm
        // not sure where else it could go. Perhaps the linkResolver?
        Request request = ObjectModelHelper.getRequest(objectModel);
        pageMeta.addMetadata("contextPath").addContent(contextPath);
        pageMeta.addMetadata("request","queryString").addContent(request.getQueryString());
        pageMeta.addMetadata("request","scheme").addContent(request.getScheme());
        pageMeta.addMetadata("request","serverPort").addContent(request.getServerPort());
        pageMeta.addMetadata("request","serverName").addContent(request.getServerName());
        pageMeta.addMetadata("request","URI").addContent(request.getSitemapURI());

        String dspaceVersion = Util.getSourceVersion();
        if (dspaceVersion != null)
        {
            pageMeta.addMetadata("dspace","version").addContent(dspaceVersion);
        }

        String analyticsKey = DSpaceServicesFactory.getInstance().getConfigurationService().getProperty("xmlui.google.analytics.key");
        if (analyticsKey != null && analyticsKey.length() > 0)
        {
                analyticsKey = analyticsKey.trim();
                pageMeta.addMetadata("google","analytics").addContent(analyticsKey);
        }

        // add metadata for OpenSearch auto-discovery links if enabled
        if (DSpaceServicesFactory.getInstance().getConfigurationService().getBooleanProperty("websvc.opensearch.autolink"))
        {
            pageMeta.addMetadata("opensearch", "shortName").addContent( DSpaceServicesFactory.getInstance().getConfigurationService().getProperty("websvc.opensearch.shortname") );
            pageMeta.addMetadata("opensearch", "autolink").addContent( "open-search/description.xml" );
        }

        pageMeta.addMetadata("page","contactURL").addContent(contextPath + "/contact");
        pageMeta.addMetadata("page","feedbackURL").addContent(contextPath + "/feedback");

        // Add the locale metadata including language-dependent labels
        Locale[] locales = I18nUtil.getSupportedLocales();
        for (int i=0; i < locales.length; i++)
        {
            pageMeta.addMetadata("page", "supportedLocale").addContent(locales[i].toString());
            // now add the appropriate labels
            pageMeta.addMetadata("supportedLocale", locales[i].toString()).addContent(locales[i].getDisplayName(locales[i]));
        }
         
        pageMeta.addMetadata("page","currentLocale").addContent(context.getCurrentLocale().toString());
        
        DSpaceObject dso = HandleUtil.obtainHandle(objectModel);
        if (dso != null)
        {
            if (dso instanceof Item)
            {
                pageMeta.addMetadata("focus","containerType").addContent("type:item");
                pageMeta.addMetadata("focus","object").addContent("hdl:"+dso.getHandle());
                this.getObjectManager().manageObject(dso);
                dso = ((Item) dso).getOwningCollection();
            }
            
            if (dso instanceof Collection)
            {
                pageMeta.addMetadata("focus","containerType").addContent("type:collection");
                pageMeta.addMetadata("focus","container").addContent("hdl:"+dso.getHandle());
                this.getObjectManager().manageObject(dso);
            }
            
            if (dso instanceof Community)
            {
                pageMeta.addMetadata("focus","containerType").addContent("type:community");
                pageMeta.addMetadata("focus","container").addContent("hdl:"+dso.getHandle());
                this.getObjectManager().manageObject(dso);
            }
        }
    }
}
