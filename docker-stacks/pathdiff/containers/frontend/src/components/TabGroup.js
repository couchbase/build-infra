import React from 'react'
import { Nav, NavItem, NavLink, } from 'reactstrap';
import { useApp } from '../context/AppContext'

function header(l, status, thing, things) {
    if (l) {
        const h = `${l.length}${status ? ' ' + status + ' ' : ' '}${l.length === 1 ? thing : things}`
        if (l.length > 0) {
            return <b>{h}</b>
        } else {
            return h
        }
    }
}

function Comparison(props) {
    const {
        edition,
        product,
        distro,
        baseVersion,
        toVersion,
    } = useApp()
    return <Nav tabs>
        <NavItem>
            <NavLink active
                onClick={() => { props.setActiveTab('1'); }}
            >
                {header(props.listing.new_binary_dirs, 'added', 'path', 'paths')}
            </NavLink>
        </NavItem>
        <NavItem>
            <NavLink
                onClick={() => { props.setActiveTab('2'); }}
            >
                {header(props.listing.new_binaries, 'added', 'binary', 'binaries')}
            </NavLink>
        </NavItem>
        <NavItem>
            <NavLink
                onClick={() => { props.setActiveTab('3'); }}
            >
                {header(props.listing.removed_binary_dirs, 'removed', 'path', 'paths')}
            </NavLink>
        </NavItem>
        <NavItem>
            <NavLink
                onClick={() => { props.setActiveTab('4'); }}
            >
                {header(props.listing.removed_binaries, 'removed', 'binary', 'binaries')}
            </NavLink>
        </NavItem>
        {props.listing &&
        <NavItem>
            <NavLink href={`http://${process.env.REACT_APP_API}/api/v1/compare?edition=${edition}&product=${product}&distro=${distro}&from_version=${baseVersion}&to_version=${toVersion}`}>
            json
                {/* // <a href={`http://${process.env.REACT_APP_API}/api/v1/compare?edition=${edition}&product=${product}&distro=${distro}&from_version=${baseVersion}&to_version=${toVersion}`}>json</a> */}
            </NavLink>
        </NavItem>}
    </Nav>
}

function Overview(props) {
    const {
        edition,
        distro,
        baseVersion,
        product
    } = useApp()
    return <Nav tabs>
        <NavItem>
            <NavLink
                onClick={() => { props.setActiveTab('1'); }}
            >
                {header(props.listing.paths, null, 'path', 'paths')}
            </NavLink>
        </NavItem>
        <NavItem>
            <NavLink
                onClick={() => { props.setActiveTab('2'); }}
            >
                {header(props.listing.files, null, 'file', 'files')}
            </NavLink>
        </NavItem>
        {props.listing &&
        <NavItem>
            <NavLink>
                <a href={`http://${process.env.REACT_APP_API}/api/v1/listing?edition=${edition}&product=${product}&distro=${distro}&version=${baseVersion}`}>json</a>
            </NavLink>
        </NavItem>}
    </Nav>
}

export default function TabGroup(props) {
    return props?.comparison ? <Comparison {...props} /> : <Overview {...props} />
}