import React, { useState } from 'react'
import TabGroup from './TabGroup';
import TabDetail from './TabDetail';
import { useApp } from '../context/AppContext'

export default function BinaryListing(props) {
    const {
        distro,
        product,
        edition,
        listing, setListing,
        route, setRoute,
        baseVersion,
        toVersion,
        toVisible
    } = useApp()

    const [activeTab, setActiveTab] = useState('1')

    React.useEffect(() => {
        function fetchListing() {
            if (distro && baseVersion) {
                let apiRoute
                if (toVisible && toVersion !== undefined) {
                    // we're comparing two versions, so structure the api call
                    // 'distro', 'product', 'from_version', 'to_version', 'edition'
                    apiRoute = `http://${process.env.REACT_APP_API}/api/v1/compare?distro=${distro}&product=${product}&edition=${edition}&from_version=${baseVersion}&to_version=${toVersion}`
                } else {
                    apiRoute = `http://${process.env.REACT_APP_API}/api/v1/listing?distro=${distro}&product=${product}&edition=${edition}&version=${baseVersion}`
                }
                if (route !== apiRoute) {
                    setRoute(apiRoute)
                    fetch(apiRoute).then(res => res.json().then(x => {
                        setListing(x)
                    }))
                }
            }
        }

        if (baseVersion) { fetchListing() }
    }, [baseVersion, toVersion, toVisible, distro, edition, product, route, setListing, setRoute])

    return <>
        <TabGroup comparison={toVisible} activeTab={activeTab} setActiveTab={setActiveTab} {...props} listing={listing} />
        <TabDetail comparison={toVisible} activeTab={activeTab} setActiveTab={setActiveTab} {...props} listing={listing} />
    </>
}

