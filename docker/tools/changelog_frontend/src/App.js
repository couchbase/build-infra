import React, { useEffect, useState } from 'react';
import { Nav, Navbar, NavItem, NavLink } from 'reactstrap'
import DetailDropdown from './components/DetailDropdown'
import Changelog from './components/Changelog'
import './App.css';
const queryString = require('query-string');

const apiUrl = 'http://build-db.build.couchbase.com:8000'

const blankLog = <>
  Choose a product, release, version and builds from the dropdowns above to view a change log.
</>

function App() {
  // headings used in the nav bar
  const heading = React.useMemo(() => {return {
    'product': 'Product',
    'fromVersion': 'Version',
    'fromBuild': 'Build',
    'toVersion': 'Version',
    'toBuild': 'Build'
  }},[])

  // selectedOptions is used to store top bar and filter selections
  const [selectedOptions] = useState(queryString.parse(window.location.search))

  // lists populated from the database
  const [products, setProducts] = useState();
  const [versions, setVersions] = useState();
  const [toBuilds, setToBuilds] = useState();
  const [fromBuilds, setFromBuilds] = useState();

  // current selections
  const [product, setProduct] = useState(selectedOptions['product'] || heading['product']);
  const [fromVersion, setFromVersion] = useState(selectedOptions['fromVersion'] || heading['fromVersion']);
  const [fromBuild, setFromBuild] = useState(selectedOptions['fromBuild'] || heading['fromBuild']);
  const [toVersion, setToVersion] = useState(selectedOptions['toVersion'] || heading['toVersion']);
  const [toBuild, setToBuild] = useState(selectedOptions['toBuild'] || heading['toBuild']);

  // We populate the dropdown selections from the querystring on page load, and don't want e.g
  // the product field changing to cause version/build info to be reset. However this is the
  // correct behaviour after the initial load, so we use optionsChanged to track where we are
  // if it's false we're onthe initial page load. It's only true only after the user has changed
  // one of the options.
  const [optionsChanged, setOptionsChanged] = useState(false);

  const [filters, setFilters] = useState({});
  useEffect(() => {
    console.log('selectedOptions:', selectedOptions)
    for (let [k, v] of Object.entries(selectedOptions)) {
      if (k.startsWith('f_')) {
        filters[k.substr(2)] = v
        setFilters({ ...filters })
      }
    }
  }, [selectedOptions])

  const [changelog, setChangelog] = useState();

  // each thing we may be loading has its own loading state, so we know
  // what we're waiting for and can generate feedback accordingly
  const [loadingProducts, setLoadingProducts] = useState(false)
  const [loadingVersions, setLoadingVersions] = useState(false)
  const [loadingToBuilds, setLoadingToBuilds] = useState(false)
  const [loadingFromBuilds, setLoadingFromBuilds] = useState(false)
  const [loadingChanges, setLoadingChanges] = useState(false)

  // construct and inject the url into the window history as selections and filters change
  useEffect(() => {
    const q = []
    product !== heading['product'] && q.push(`product=${product}`)
    fromVersion !== heading['fromVersion'] && q.push(`fromVersion=${fromVersion}`)
    fromBuild !== heading['fromBuild'] && q.push(`fromBuild=${fromBuild}`)
    toVersion !== heading['toVersion'] && q.push(`toVersion=${toVersion}`)
    toBuild !== heading['toBuild'] && q.push(`toBuild=${toBuild}`)
    let filterString = Object.keys(filters).filter(f => f !== '_').map(filter => `f_${filter}=${filters[filter]}`).join('&')
    if (fromBuild === heading['fromBuild']) filterString = ''
    let qs = `${q.length>0 ? "?" : ""}${q.join('&')}${filterString ? "&" : ""}${filterString}`
    window.history.pushState(null, null, qs)
  }, [heading, product, fromVersion, fromBuild, toVersion, toBuild, filters])

  // load product list
  useEffect(() => {
    // TODO: not sure how to query for products containing slashes - e.g. cbdeps/jemalloc, just ignoring them for now
    setLoadingProducts(true)
    fetch(
      `${apiUrl}/v1/products`
    ).then(res => res.json().then(json => setProducts(json.products.filter(x => !x.includes('/'))))).then(() => {
      setLoadingProducts(false)
    });
  }, []);

  // load product versions
  useEffect(() => {
    if (product !== heading['product']) {
      setLoadingVersions(true)
      if(optionsChanged) {
        // reset other fields and changelog to default if the user changed the product
        setFromVersion(heading['fromVersion'])
        setToVersion(heading['toVersion'])
        setFromBuild(heading['fromBuild'])
        setToBuild(heading['toBuild'])
        setChangelog()
      }
      fetch(
        `${apiUrl}/v1/products/${product}/versions`
      ).then(res => res.json().then(json => {
        setVersions(json.versions.sort())
      })).then(() => {
        setLoadingVersions(false)
      })
    }
  }, [product]);

  // load from builds
  useEffect(() => {
    if (fromVersion !== heading['fromVersion']) {
      setLoadingFromBuilds(true)
      fetch(
        `${apiUrl}/v1/products/${product}/versions/${fromVersion}/builds`
      ).then(res => res.json().then(json => {
        setFromBuilds(json.builds)
      })).then(() => {
        if (optionsChanged) {
          setFilters({ '_': '_' })
          setFromBuild(heading['fromBuild'])
          setToVersion(fromVersion)
        }
      }).then(() => {
        setLoadingFromBuilds(false)
      })
    }
  }, [fromVersion]);

  // set toBuilds when fromBuilds changes
  useEffect(() => {
      fromBuilds && toVersion === fromVersion && setToBuilds(fromBuilds)
  }, [fromBuilds])

  // load toBuilds when toVersion changes
  useEffect(() => {
    if (toVersion !== heading['toVersion']) {
      setLoadingToBuilds(true)
      if (toVersion === fromVersion) {
        if (fromBuild !== heading['fromBuild']) {
          fromBuilds && setToBuilds(fromBuilds.filter(x => x > fromBuild))
        } else {
          fromBuilds && setToBuilds(fromBuilds)
        }
        setLoadingToBuilds(false)
      } else {
        if (toVersion < fromVersion) {
          setFromVersion(toVersion)
          setFromBuild(heading['fromBuild'])
          setToBuild(heading['toBuild'])
          setLoadingToBuilds(false)
        } else {
          fetch(
            `${apiUrl}/v1/products/${product}/versions/${toVersion}/builds`
          ).then(res => res.json().then(json => {
            setToBuilds(json.builds)
          })).then(() => {
            if (optionsChanged) {
              setFilters({ '_': '_' })
              setToBuild(heading['toBuild'])
            }
          }).then(() => {
            setLoadingToBuilds(false)
          })
        }
      }
    }
  }, [toVersion]);

  useEffect(() => {
    if (toVersion === fromVersion && toBuild < fromBuild) {
      setFromBuild(toBuild)
    } else {
      getChangeLog()
    }
  }, [toBuild])

  useEffect(() => {
    if (optionsChanged) {
      setToBuild(heading['toBuild'])
      if(toVersion === fromVersion) {
        setToBuilds(fromBuilds.filter(x => x > fromBuild))
      }
    }
  }, [fromBuild])

  function getChangeLog() {
    if (toBuild !== heading['toBuild'] && fromBuild !== heading['fromBuild']) {
      setLoadingChanges(true)
      fetch(
        `${apiUrl}/v1/changeset/${product}?from=${fromVersion}-${fromBuild}&to=${toVersion}-${toBuild}`
      ).then(res => res.json().then(json => {
        setChangelog(json)
      })).then(() => {
        setLoadingChanges(false)
      })
    } else {
      setChangelog()
    }
  };

  // retrieve an array of the things we are currently loading
  // note: frombuilds and tobuilds are treated as a single entry - 'builds'
  function loading() {
    let retrieving = []
    if (loadingProducts) retrieving.push('products')
    if (loadingVersions) retrieving.push('versions')
    if (loadingFromBuilds) retrieving.push('builds')
    if (loadingToBuilds) retrieving.push('builds')
    if (loadingChanges) retrieving.push('changes')
    return (Array.from(new Set(retrieving)))
  }

  return (
    <div id="OuterContainer">
      <Navbar color="light" light expand="md">
        <Nav className="mr-auto" navbar>
          <DetailDropdown name={heading['product']} direction='asc' type={product} items={products} setter={setProduct} commit={setOptionsChanged} />

          <>
            <NavItem><NavLink>From</NavLink></NavItem>
            <DetailDropdown name={heading['fromVersion']} direction='desc' type={fromVersion} items={versions} setter={setFromVersion} commit={setOptionsChanged} />
          </>

          <DetailDropdown name={heading['fromBuild']} direction='desc' type={fromBuild} items={fromBuilds} setter={setFromBuild} commit={setOptionsChanged} />

          <>
            <NavItem><NavLink>To</NavLink></NavItem>
            <DetailDropdown name={heading['toVersion']} direction='desc' type={toVersion} items={versions} setter={setToVersion} commit={setOptionsChanged} />
          </>

          <DetailDropdown name={heading['toBuild']} direction='desc' type={toBuild} items={toBuilds} setter={setToBuild} commit={setOptionsChanged} />

        </Nav>
      </Navbar>

      <Changelog id="InnerContainer"
        from={fromBuild}
        fromVersion={fromVersion}
        key={`${product}-${fromVersion}-${fromBuild}-${toVersion}-${toBuild}-changelog`}
        loading={loading()}
        log={changelog}
        placeholder={blankLog}
        product={product}
        querystringFilters={filters}
        setQuerystringFilters={setFilters}
        to={toBuild}
        toVersion={toVersion} />
    </div>
  );
}

export default App;
