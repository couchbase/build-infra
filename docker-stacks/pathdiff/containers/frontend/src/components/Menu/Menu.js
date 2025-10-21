import React from 'react';
import { DistroField, VersionField } from './'
import { Button, ButtonGroup, Collapse } from 'reactstrap';
import { useApp } from '../../context/AppContext'
import { useNavigate, useLocation } from "react-router-dom"

export default function Menu(props) {
    const {
        distro,
        versions, setVersions,
        setBaseVersion,
        toVersion, setToVersion,
        toVisible, setToVisible
    } = useApp()
    const navigate = useNavigate()
    const location = useLocation()

    return <div>
        <DistroField type="distros" heading="Distro" value={distro}></DistroField>
        <VersionField type="baseVersion" heading={toVisible ? "From" : "Version"} updater="true" setter={setBaseVersion}></VersionField>
        <Collapse isOpen={toVisible}>
            <VersionField type="toVersion" heading={'To'} distro={distro} value={toVersion} setter={setToVersion} list={versions} listSetter={setVersions} toVisible={toVisible}></VersionField>
        </Collapse>
        <ButtonGroup id="menuButtons">
            <Button style={{width: "100%"}} onClick={() => {
                if (versions) {
                    if (!toVersion) {
                        setToVersion(versions[versions.length-1])
                        const params = new URLSearchParams(location.search)
                        params.append("toVersion", versions[versions.length-1])
                        navigate.push({ search: params.toString() })
                    }
                }
                if (toVisible) {
                    const params = new URLSearchParams(location.search)
                    params.delete("toVersion")
                    navigate.push({ search: params.toString() })
                }
                setToVisible(!toVisible)
            }
            }>{toVisible ? "Remove comparison" : "Add comparison"}</Button>
        </ButtonGroup>
    </div>
}
