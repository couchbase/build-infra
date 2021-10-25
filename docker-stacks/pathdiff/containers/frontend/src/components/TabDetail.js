import React from 'react'
import { Card, CardTitle, CardText, Row, Col, TabContent, TabPane } from 'reactstrap';

function Comparison(props) {
    return <TabContent activeTab={props.activeTab}>
        <TabPane tabId="1">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props?.listing?.to_version ? `Paths present in ${props.listing.to_version} (${props.listing.to_build}), absent in ${props.listing.from_version} (${props.listing.from_build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.new_binary_dirs?.map(p => <span key={p} className="filename">{p}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
        <TabPane tabId="2">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props.listing?.to_version ? `Binaries present in ${props.listing.to_version} (${props.listing.to_build}), absent in ${props.listing.from_version} (${props.listing.from_build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.new_binaries?.map(p => <span key={p} className="filename">{p}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
        <TabPane tabId="3">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props.listing?.from_version ? `Paths present in ${props.listing.from_version} (${props.listing.from_build}), absent in ${props.listing.to_version} (${props.listing.to_build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.removed_binary_dirs?.map(f => <span key={f} className="filename">{f}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
        <TabPane tabId="4">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props.listing?.from_version ? `Binaries present in ${props.listing.from_version} (${props.listing.from_build}), absent in ${props.listing.to_version} (${props.listing.to_build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.removed_binaries?.map(f => <span key={f} className="filename">{f}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
    </TabContent>
}

function Overview(props) {
    return <TabContent activeTab={props.activeTab}>
        <TabPane tabId="1">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props.listing?.version ? `Binary paths detected in ${props.listing.version} (${props.listing.build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.paths?.map(p => <span key={p} className="filename">{p}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
        <TabPane tabId="2">
            <Row>
                <Col sm="12">
                    <Card body>
                        <CardTitle>{props.listing?.version ? `Binary files detected in ${props.listing.version} (${props.listing.build}) on ${props.listing.distro}` : "Loading"}</CardTitle>
                        <CardText>{props?.listing?.files?.map(f => <span key={f} className="filename">{f}<br /></span>)}</CardText>
                    </Card>
                </Col>
            </Row>
        </TabPane>
    </TabContent>
}

export default function TabDetail(props) {
    return props?.comparison ? <Comparison {...props} /> : <Overview {...props} />
}