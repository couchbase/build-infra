import React, { createContext, useContext, useState } from 'react';
import { useLocation } from "react-router-dom"


const AppContext = createContext();

export const AppProvider = (props) => {
    const location = useLocation()
    const params = new URLSearchParams(location.search)

    const [distro, setDistro] = useState(params.get('distro', ''))
    const [render, setRender] = useState(false)
    const [distros, setDistros] = useState()
    const [versions, setVersions] = useState()
    const [baseVersion, setBaseVersion] = useState(params.get('baseVersion', ''))
    const [toVersion, setToVersion] = useState(params.get('toVersion', ''))
    const [notificationMessage, setNotificationMessage] = useState("")
    const [notificationColor, setNotificationColor] = useState("info")
    const [toVisible, setToVisible] = useState(params.get('toVersion') ? true : false)
    const [product, setProduct] = useState('couchbase-server')
    const [edition, setEdition] = useState('enterprise')
    const [listing, setListing] = useState('')
    const [route, setRoute] = useState()

    return (
        <AppContext.Provider value={{
            render, setRender,
            distros, setDistros,
            versions, setVersions,
            distro, setDistro,
            product, setProduct,
            edition, setEdition,
            listing, setListing,
            route, setRoute,
            baseVersion, setBaseVersion,
            toVersion, setToVersion,
            notificationMessage, setNotificationMessage,
            notificationColor, setNotificationColor,
            toVisible, setToVisible
        }}>
            {props.children}
        </AppContext.Provider>
    )
}

export const useApp = () => useContext(AppContext)
